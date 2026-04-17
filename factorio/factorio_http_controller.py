#!/usr/bin/env python3
"""
Factorio HTTP Controller

HTTP API server that bridges agent_scripts and Factorio RCON.
The controller handles:
- Game state retrieval (inspect, get-reachable)
- Action execution via RCON
- Reference data caching (recipes, technologies)
- LLM workflow execution (optional)
"""

import ollama
import time
import json
import os
import subprocess
import signal
import sys
import threading
import math
import factorio_rcon
from typing import Dict, List, Optional
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
try:
    import requests
except ImportError:
    print("⚠️  'requests' library not found. Install with: pip install requests")
    sys.exit(1)

# 12-factor: env vars override config (containers use env; local dev uses config.py)
def _env_or_config(env_key: str, default):
    v = os.environ.get(env_key)
    if v is not None and v != "":
        return int(v) if isinstance(default, int) else v
    return default

try:
    from config import (
        RCON_HOST, RCON_PORT, RCON_PASSWORD,
        OLLAMA_MODEL, OLLAMA_HOST, OLLAMA_PORT,
        MAX_RANGE_FROM_BASE,
    )
except ImportError:
    RCON_HOST, RCON_PORT, RCON_PASSWORD = "192.168.0.158", 27015, ""
    OLLAMA_MODEL, OLLAMA_HOST, OLLAMA_PORT = "phi3:mini", "localhost", 11434
    MAX_RANGE_FROM_BASE = 200

RCON_HOST = _env_or_config("RCON_HOST", RCON_HOST)
RCON_PORT = _env_or_config("RCON_PORT", RCON_PORT)
RCON_PASSWORD = _env_or_config("RCON_PASSWORD", RCON_PASSWORD)
OLLAMA_MODEL = _env_or_config("OLLAMA_MODEL", OLLAMA_MODEL)
OLLAMA_HOST = _env_or_config("OLLAMA_HOST", OLLAMA_HOST)
OLLAMA_PORT = _env_or_config("OLLAMA_PORT", OLLAMA_PORT)
MAX_RANGE_FROM_BASE = _env_or_config("MAX_RANGE_FROM_BASE", MAX_RANGE_FROM_BASE)

# Reference data (recipes/technologies) written when RCON connects. Set REFERENCE_DATA_DISABLED=1 to disable.
_ref_disabled = os.environ.get("REFERENCE_DATA_DISABLED", "").lower() in ("1", "true", "yes")
REFERENCE_DATA_DIR = None if _ref_disabled else (os.environ.get("REFERENCE_DATA_DIR", ".reference_data") or ".reference_data").strip()
REFERENCE_REFRESH_DEBOUNCE_SEC = int(os.environ.get("REFERENCE_REFRESH_DEBOUNCE_SEC", "300"))  # max once per 5 min


class FactorioActionHandler(BaseHTTPRequestHandler):
    """HTTP handler for n8n to call RCON actions."""
    
    def __init__(self, controller, *args, **kwargs):
        self.controller = controller
        super().__init__(*args, **kwargs)
    
    def _action_result_to_dict(self, raw, action: str) -> dict:
        """Turn execute_action raw return into {success, message}."""
        if raw is True:
            return {'success': True, 'message': f'Action {action} executed successfully'}
        if isinstance(raw, str):
            err = ['error', 'cannot', 'unknown', 'failed', 'insufficient', 'not found']
            return {'success': False, 'message': raw} if any(x in raw.lower() for x in err) else {'success': True, 'message': raw}
        return {'success': bool(raw), 'message': str(raw)}

    def do_POST(self):
        """Handle POST: /ai-step, /execute-action (single), or /queue-actions (chain)."""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        parsed = urlparse(self.path)

        try:
            data = json.loads(body.decode('utf-8')) if body else {}
            agent_id = data.get('agent_id') or "1"

            if parsed.path == '/ai-step':
                try_modes = data.get('try_modes')  # ordered list; if present, try each until one has work
                mode = data.get('mode') or 'follow'
                last_result = data.get('last_result')
                fast = data.get('fast', False)
                resource = data.get('resource')
                out = self.controller.run_one_ai_step(agent_id, mode=mode, last_result=last_result, fast=fast, resource=resource, try_modes=try_modes)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(out).encode('utf-8'))
                return
            if parsed.path == '/queue-actions':
                actions = data.get('actions') or []
                if not isinstance(actions, list):
                    raise ValueError('actions must be a list')
                results = []
                overall = True
                for i, step in enumerate(actions):
                    action = step.get('action')
                    params = step.get('params') or {}
                    if not action:
                        results.append({'step_index': i, 'action': '', 'success': False, 'message': 'missing action'})
                        overall = False
                        break
                    raw = self.controller.execute_action(agent_id, action, params)
                    out = self._action_result_to_dict(raw, action)
                    results.append({'step_index': i, 'action': action, 'success': out['success'], 'message': out['message']})
                    if not out['success']:
                        overall = False
                        break
                response = {'results': results, 'overall_success': overall}
            else:
                # /execute-action or legacy single POST
                action = data.get('action')
                params = data.get('params', {})
                raw = self.controller.execute_action(agent_id, action, params)
                response = self._action_result_to_dict(raw, action)

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': False, 'message': str(e)}).encode('utf-8'))
    
    def do_GET(self):
        """Handle GET requests (for health checks, etc.)."""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/health':
            # Health check endpoint
            rcon_status = 'connected' if self.controller.factorio is not None else 'disconnected'
            response = {
                'status': 'healthy',
                'rcon': rcon_status,
                'service': 'factorio-http-controller'
            }
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/get-reachable':
            query_params = parse_qs(parsed_path.query)
            agent_id = query_params.get('agent_id', [None])[0]
            if agent_id:
                reachable = self.controller.get_reachable_entities(agent_id)
                response = reachable if reachable else {}
            else:
                response = {'error': 'agent_id required'}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/inspect':
            query_params = parse_qs(parsed_path.query)
            agent_id = query_params.get('agent_id', [None])[0]
            if agent_id:
                state = self.controller.get_agent_state(agent_id)
                response = state if state else {}
            else:
                response = {'error': 'agent_id required'}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/get-recipes':
            query_params = parse_qs(parsed_path.query)
            agent_id = query_params.get('agent_id', [None])[0]
            if agent_id:
                data = self.controller.get_recipes(agent_id)
                response = data if data else {}
            else:
                response = {'error': 'agent_id required'}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/get-technologies':
            query_params = parse_qs(parsed_path.query)
            agent_id = query_params.get('agent_id', [None])[0]
            researched = query_params.get('researched_only', ['false'])[0].lower() == 'true'
            if agent_id:
                data = self.controller.get_technologies(agent_id, researched_only=researched)
                response = data if data else {}
            else:
                response = {'error': 'agent_id required'}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/player-position':
            pos = self.controller.get_player_position()
            response = pos if pos else {}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path == '/players':
            players = self.controller.refresh_player_context()
            response = players if players is not None else []
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        elif parsed_path.path.startswith("/reference/"):
            rest = parsed_path.path.replace("/reference/", "").strip("/")
            parts = rest.split("/", 1)
            if rest in ("recipes", "technologies", "technologies_researched"):
                base = getattr(self.controller, "_ref_data_dir", None)
                if base:
                    path = os.path.join(os.path.abspath(base), f"{rest}.json")
                    if os.path.isfile(path):
                        with open(path, "r") as f:
                            body = f.read()
                        self.send_response(200)
                        self.send_header("Content-type", "application/json")
                        self.send_header("Content-Length", str(len(body.encode("utf-8"))))
                        self.end_headers()
                        self.wfile.write(body.encode("utf-8"))
                        return
            elif len(parts) == 2:
                kind, lookup_name = parts[0], parts[1]
                if kind == "recipe" and lookup_name:
                    obj = self.controller.get_reference_recipe(lookup_name)
                    if obj is not None:
                        body = json.dumps(obj)
                        self.send_response(200)
                        self.send_header("Content-type", "application/json")
                        self.end_headers()
                        self.wfile.write(body.encode("utf-8"))
                        return
                elif kind == "technology" and lookup_name:
                    obj = self.controller.get_reference_technology(lookup_name)
                    if obj is not None:
                        body = json.dumps(obj)
                        self.send_response(200)
                        self.send_header("Content-type", "application/json")
                        self.end_headers()
                        self.wfile.write(body.encode("utf-8"))
                        return
            self.send_response(404)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


class FactorioN8NController:
    """Simplified controller that uses n8n for workflow execution."""
    
    def __init__(self, rcon_host: str = "localhost", rcon_port: int = 27015,
                 rcon_password: str = "", ollama_model: str = "phi3:mini",
                 ollama_host: str = "localhost", ollama_port: int = 11434,
                 n8n_url: str = "http://192.168.0.158:30109"):
        """
        Initialize the n8n-based NPC controller.
        
        Args:
            n8n_url: Base URL of n8n instance
        """
        # Initialize RCON client (connect lazily to handle server not being ready)
        self.rcon_host = rcon_host
        self.rcon_port = rcon_port
        self.rcon_password = rcon_password
        self.factorio = None
        self.ollama_model = ollama_model
        self.ollama_host = ollama_host
        self.ollama_port = ollama_port
        self.n8n_url = n8n_url
        self.npc_contexts: Dict[str, List[Dict]] = {}
        self.agent_counter = 0
        self.max_range = MAX_RANGE_FROM_BASE
        
        # HTTP server for n8n to call
        self.http_server = None
        self.http_thread = None
        
        # Set Ollama host/port
        if ollama_host != "localhost" or ollama_port != 11434:
            os.environ['OLLAMA_HOST'] = f"{ollama_host}:{ollama_port}"
        
        # Track Ollama process
        self.ollama_process = None
        self.ollama_started_by_us = False
        
        # Start HTTP server for n8n
        self.start_http_server()
        
        # Reference data: written when RCON connects so any LLM/client use catches mod changes
        self._ref_data_dir = REFERENCE_DATA_DIR or None
        self._ref_data_lock = threading.Lock()
        self._ref_data_last_start: float = 0
        # Player tracking: refreshed before every LLM prompt, injected into every prompt
        self._last_player_context: List[Dict] = []
        self._follow_min_tiles = int(os.environ.get("FOLLOW_MIN_TILES", "5"))
        # Try to connect to RCON (but don't fail if server isn't ready)
        self._connect_rcon()
    
    def _connect_rcon(self):
        """Connect to RCON server (with retry on failure)."""
        try:
            self.factorio = factorio_rcon.RCONClient(self.rcon_host, self.rcon_port, self.rcon_password)
            self.factorio.connect()
            print(f"✅ Connected to Factorio RCON at {self.rcon_host}:{self.rcon_port}")
            self._schedule_refresh_reference_data()
        except Exception as e:
            print(f"⚠️  Could not connect to Factorio RCON: {e}")
            print(f"   Will retry when actions are needed. Server may not be running yet.")
            self.factorio = None
    
    def _schedule_refresh_reference_data(self):
        """Start background refresh of recipes/technologies when RCON is used (catches mod changes)."""
        if not getattr(self, "_ref_data_dir", None) or not self._ref_data_dir:
            return
        now = time.time()
        with self._ref_data_lock:
            if now - self._ref_data_last_start < REFERENCE_REFRESH_DEBOUNCE_SEC:
                return
            self._ref_data_last_start = now
        def run():
            try:
                self._refresh_reference_data_impl()
            except Exception as e:
                print(f"⚠️  Reference data refresh failed: {e}")
        t = threading.Thread(target=run, daemon=True)
        t.start()
    
    def _refresh_reference_data_impl(self):
        """Fetch recipes/technologies via RCON and write to REFERENCE_DATA_DIR."""
        if not self._ref_data_dir or self.factorio is None:
            return
        agent_id = os.environ.get("REFERENCE_AGENT_ID", "1")
        base = os.path.abspath(self._ref_data_dir)
        os.makedirs(base, exist_ok=True)
        def strip_meta(obj):
            if isinstance(obj, list):
                return obj
            if isinstance(obj, dict):
                return {k: v for k, v in obj.items() if k not in ("_raw", "_note")}
            return obj
        recipes_data = None
        technologies_data = None
        for label, fn, store in [
            ("recipes", lambda: self.get_recipes(agent_id), "recipes_data"),
            ("technologies", lambda: self.get_technologies(agent_id, researched_only=False), "technologies_data"),
            ("technologies_researched", lambda: self.get_technologies(agent_id, researched_only=True), None),
        ]:
            try:
                data = fn()
                if store == "recipes_data":
                    recipes_data = data
                elif store == "technologies_data":
                    technologies_data = data
                clean = strip_meta(data) if isinstance(data, (dict, list)) else data
                path = os.path.join(base, f"{label}.json")
                with open(path, "w") as f:
                    json.dump(clean, f, indent=2)
                print(f"📦 Wrote reference data: {path}")
            except Exception as e:
                print(f"⚠️  Failed to write {label}: {e}")
        self._refresh_reference_details_via_rcon(base, recipes_data=recipes_data, technologies_data=technologies_data)
    
    def _build_details_from_mod_output(self, base: str, recipes_data, technologies_data) -> None:
        """Build recipe_details.json and technology_details.json from mod get_recipes/get_technologies when game protos are unavailable."""
        def recipe_list(data):
            if data is None:
                return []
            if isinstance(data, list):
                return [x if isinstance(x, dict) else {"name": str(x)} for x in data]
            if isinstance(data, dict):
                for k in ("recipes", "items", "names"):
                    if k in data and isinstance(data[k], list):
                        return [x if isinstance(x, dict) else {"name": str(x)} for x in data[k]]
            return []
        def tech_list(data):
            if data is None:
                return []
            if isinstance(data, list):
                return [x if isinstance(x, dict) else {"name": str(x)} for x in data]
            if isinstance(data, dict):
                for k in ("technologies", "items", "names"):
                    if k in data and isinstance(data[k], list):
                        return [x if isinstance(x, dict) else {"name": str(x)} for x in data[k]]
            return []
        recipe_entries = recipe_list(recipes_data)
        tech_entries = tech_list(technologies_data)
        recipe_details = {}
        for r in recipe_entries:
            n = r.get("name") if isinstance(r, dict) else str(r)
            if n:
                recipe_details[n] = dict(r) if isinstance(r, dict) else {"name": n}
        technology_details = {}
        for t in tech_entries:
            n = t.get("name") if isinstance(t, dict) else str(t)
            if n:
                technology_details[n] = dict(t) if isinstance(t, dict) else {"name": n}
        for name, data in [("recipe_details", recipe_details), ("technology_details", technology_details)]:
            if not data:
                continue
            path = os.path.join(base, f"{name}.json")
            try:
                with open(path, "w") as f:
                    json.dump(data, f, indent=2)
                print(f"📦 Wrote reference data: {path} (from mod output, {len(data)} entries)")
            except Exception as e:
                print(f"⚠️  Failed to write {name}: {e}")

    def _refresh_reference_details_via_rcon(self, base: str, recipes_data=None, technologies_data=None) -> None:
        """Fetch per-recipe and per-technology details. Uses game protos when available; else builds from mod get_recipes/get_technologies."""
        if self.factorio is None:
            return
        # Recipe details: name -> {ingredients, products, category, energy}. Use (e.type or 'item') for nil safety.
        recipe_lua = (
            "local t={} for n,r in pairs(game.recipe_prototypes) do if r.enabled then "
            "local i={} for _,e in pairs(r.ingredients) do i[#i+1]={name=e.name,amount=e.amount or 0,type=e.type or 'item'} end "
            "local pr={} for _,e in pairs(r.products) do local am=e.amount "
            "if not am and e.amount_min and e.amount_max then am=(e.amount_min+e.amount_max)/2 elseif not am then am=1 end "
            "pr[#pr+1]={name=e.name,amount=am,type=e.type or 'item'} end "
            "t[n]={name=r.name,ingredients=i,products=pr,category=r.category or '',energy=r.energy} end end "
            "if rcon and helpers then rcon.print(helpers.table_to_json(t)) end"
        )
        tech_lua = (
            "local t={} for n,tp in pairs(game.technology_prototypes) do if tp.enabled then "
            "local pre={} for pn,_ in pairs(tp.prerequisites or {}) do pre[#pre+1]=pn end "
            "local ru={} for _,e in pairs(tp.research_unit_ingredients or {}) do ru[#ru+1]={name=e.name,amount=e.amount or 0,type=e.type or 'item'} end "
            "t[n]={name=tp.name,prerequisites=pre,research_unit_ingredients=ru,research_unit_count=tp.research_unit_count or 0,research_unit_energy=tp.research_unit_energy or 0} end end "
            "if rcon and helpers then rcon.print(helpers.table_to_json(t)) end"
        )
        wrote_recipe = False
        wrote_tech = False
        for name, lua in [("recipe_details", recipe_lua), ("technology_details", tech_lua)]:
            try:
                raw = self.factorio.send_command("/sc " + lua)
                raw = (raw or "").strip()
                if raw and ("recipe_prototypes" in raw or "technology_prototypes" in raw) and "doesn't contain key" in raw:
                    raw = ""
                if not raw:
                    continue
                data = json.loads(raw)
                path = os.path.join(base, f"{name}.json")
                with open(path, "w") as f:
                    json.dump(data, f, indent=2)
                print(f"📦 Wrote reference data: {path}")
                wrote_recipe = wrote_recipe or "recipe" in name
                wrote_tech = wrote_tech or "technology" in name
            except json.JSONDecodeError:
                if raw and "doesn't contain key" in raw:
                    print(f"⚠️  {name}: game protos not in RCON context — using mod output fallback")
                else:
                    print(f"⚠️  Failed to write {name}: invalid JSON. RCON preview: {(raw or '')[:200]!r}")
            except Exception as e:
                print(f"⚠️  Failed to write {name}: {e}")
        if (not wrote_recipe or not wrote_tech) and (recipes_data is not None or technologies_data is not None):
            self._build_details_from_mod_output(base, recipes_data, technologies_data)
    
    def _reference_context_for_llm(self) -> str:
        """One-line pointer so the LLM looks up recipes/technologies on demand instead of dumping full lists."""
        if not getattr(self, "_ref_data_dir", None) or not self._ref_data_dir:
            return ""
        return (
            "## Recipe / technology lookup (on demand)\n"
            "Do not list all recipes or technologies. Look up by name: "
            "GET /reference/recipe/<name> for ingredients/products; "
            "GET /reference/technology/<name> for prerequisites and dependency chain."
        )
    
    def get_reference_recipe(self, name: str) -> Optional[Dict]:
        """Return one recipe's details (ingredients, products, category, energy) from cache. None if missing."""
        base = getattr(self, "_ref_data_dir", None)
        if not base or not name:
            return None
        path = os.path.join(os.path.abspath(base), "recipe_details.json")
        if not os.path.isfile(path):
            return None
        try:
            with open(path, "r") as f:
                data = json.load(f)
            return data.get(name) if isinstance(data, dict) else None
        except Exception:
            return None
    
    def get_reference_technology(self, name: str) -> Optional[Dict]:
        """Return one technology's details plus prerequisite_chain (all prerequisites recursively) from cache."""
        base = getattr(self, "_ref_data_dir", None)
        if not base or not name:
            return None
        path = os.path.join(os.path.abspath(base), "technology_details.json")
        if not os.path.isfile(path):
            return None
        try:
            with open(path, "r") as f:
                data = json.load(f)
            if not isinstance(data, dict):
                return None
            tech = data.get(name)
            if not tech or not isinstance(tech, dict):
                return None
            out = dict(tech)
            prereqs = out.get("prerequisites") or []
            seen = set()
            chain = []
            def add_chain(n):
                if n in seen or n not in data:
                    return
                seen.add(n)
                for p in (data.get(n) or {}).get("prerequisites") or []:
                    add_chain(p)
                chain.append(n)
            for p in prereqs:
                add_chain(p)
            out["prerequisite_chain"] = chain
            return out
        except Exception:
            return None
    
    def start_http_server(self, port: int = 8080):
        """Start HTTP server for n8n to call."""
        def handler(*args, **kwargs):
            return FactorioActionHandler(self, *args, **kwargs)
        
        try:
            self.http_server = HTTPServer(('0.0.0.0', port), handler)
            
            def run_server():
                print(f"🌐 HTTP server thread started, listening on 0.0.0.0:{port}")
                self.http_server.serve_forever()
            
            self.http_thread = threading.Thread(target=run_server, daemon=True)
            self.http_thread.start()
            print(f"✅ HTTP server started on 0.0.0.0:{port} (accessible from network) for n8n actions")
        except Exception as e:
            print(f"❌ Failed to start HTTP server: {e}")
            import traceback
            traceback.print_exc()
    
    def check_ollama_running(self) -> bool:
        """Check if Ollama is running."""
        try:
            response = requests.get(f"http://{self.ollama_host}:{self.ollama_port}/api/tags", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def start_ollama(self):
        """Start Ollama if not running."""
        if self.check_ollama_running():
            print("✅ Ollama is already running")
            return
        
        print("Starting Ollama...")
        try:
            self.ollama_process = subprocess.Popen(
                ['ollama', 'serve'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            self.ollama_started_by_us = True
            
            # Wait for Ollama to start
            for i in range(10):
                time.sleep(1)
                if self.check_ollama_running():
                    print("✅ Ollama started successfully")
                    return
            
            print("⚠️  Ollama may not have started properly")
        except FileNotFoundError:
            # Try brew services
            try:
                subprocess.run(['brew', 'services', 'start', 'ollama'], check=True)
                self.ollama_started_by_us = True
                print("✅ Started Ollama via brew services")
            except:
                print("❌ Could not start Ollama. Please start it manually.")
    
    # Include all the existing methods from FactorioNPCController
    # (get_agent_state, is_agent_busy, execute_action, etc.)
    # ... (copy from factorio_ollama_npc_controller.py)
    
    def trigger_n8n_workflow(self, workflow_name: str, agent_id: str, params: Dict) -> Dict:
        """
        Trigger an n8n workflow via webhook.
        
        Args:
            workflow_name: Name of workflow to trigger (e.g., "gather-resource")
            agent_id: Agent ID
            params: Workflow parameters
        
        Returns:
            Dict with success and message
        """
        webhook_url = f"{self.n8n_url}/webhook/{workflow_name}"
        
        payload = {
            "agent_id": agent_id,
            "params": params
        }
        
        try:
            response = requests.post(webhook_url, json=payload, timeout=60)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {'success': False, 'message': f'Failed to trigger n8n workflow: {e}'}
    
    def query_llm_for_workflow(self, agent_id: str, game_state: str, agent_state: Optional[Dict], 
                               reachable: Optional[Dict] = None, last_result: Optional[str] = None) -> Optional[Dict]:
        """
        Query LLM to choose which n8n workflow to run.
        
        Returns:
            Dict with 'workflow' and 'params' keys
        """
        # Initialize context if needed
        if agent_id not in self.npc_contexts:
            min_t = getattr(self, "_follow_min_tiles", 5)
            self.npc_contexts[agent_id] = [{
                "role": "system",
                "content": f"""You are a Factorio NPC agent controller. Choose which n8n workflow to run.

Available workflows:
- gather-resource: Mine a resource (params: {{"resource_name": "iron-ore"}})
- build-blueprint: Build a ghost entity (params: {{"ghost_entity": {{...}}}})
- defend-base: Move to enemy (params: {{"enemy": {{...}}}})
- build-chest-and-fill: Gather wood, build chest, fill it (params: {{}})
- patrol: Walk in circles (params: {{"center": {{"x": 0, "y": 0}}, "radius": 50}})

Rules:
- Only defend if enemies present
- Only build if blueprints exist
- Do not bring the agent closer than {min_t} tiles to any player.
- Default to build-chest-and-fill when idle

Response format: {{"workflow": "workflow-name", "params": {{...}}}}"""
            }]
        
        self.refresh_player_context()
        player_ctx = self._player_context_for_llm(agent_state.get("position") if agent_state else None)
        ref_snippet = self._reference_context_for_llm()
        context = f"""Choose which n8n workflow to run.

## Sensing (how far the agent sees)
{self._SENSING_RANGES}

{player_ctx}

## Previous Result
{last_result if last_result else "No previous workflow - first decision."}

## Game State
{json.dumps({
    'agent_state': agent_state,
    'reachable': reachable
}, indent=2)}
{f'''

{ref_snippet}
''' if ref_snippet else ''}

## Response Format
{{"workflow": "workflow-name", "params": {{...}}}}
"""
        
        self.npc_contexts[agent_id].append({"role": "user", "content": context})
        
        try:
            response = ollama.chat(
                model=self.ollama_model,
                messages=self.npc_contexts[agent_id],
                format="json",
                options={
                    "temperature": 0.7,
                    "num_predict": 200
                }
            )
            
            content = response['message']['content']
            decision = json.loads(content)
            
            # Add assistant response to history
            self.npc_contexts[agent_id].append({"role": "assistant", "content": content})
            
            # Limit history
            if len(self.npc_contexts[agent_id]) > 11:  # System + 10 messages
                self.npc_contexts[agent_id] = [self.npc_contexts[agent_id][0]] + self.npc_contexts[agent_id][-10:]
            
            return decision
        except Exception as e:
            print(f"❌ Error querying LLM: {e}")
            return None

    _SENSING_RANGES = (
        "Resources (ore, trees, rocks): ~2.7 tiles from you — use for mining/harvesting. "
        "Other entities (machines, chests, ghosts): ~10 tiles — use for build/loot/configure."
    )

    def query_llm_for_action(self, agent_id: str, agent_state: Optional[Dict], reachable: Optional[Dict],
                             player_position: Optional[Dict], last_result: Optional[str] = None) -> Optional[Dict]:
        """Ask LLM for one direct action (follow-me mode). Returns {action, params} or None."""
        ctx_key = f"{agent_id}_follow"
        min_tiles = getattr(self, "_follow_min_tiles", 5)
        if ctx_key not in self.npc_contexts:
            self.npc_contexts[ctx_key] = [{
                "role": "system",
                "content": f"""You control a Factorio agent that should follow the player to resource patches.

SENSING (how far the agent can see):
- Resources (ore, trees, rocks): ~2.7 tiles from the agent — can mine/harvest only within this.
- Other entities (machines, chests, ghosts): ~10 tiles — can place/configure/loot within this.

RULE — keep distance: Do not come closer than {min_tiles} tiles to any player. When following, use the "Suggested follow target" as your walk_to target, not the player's position.

Return exactly one action per turn. Response must be valid JSON only.
Allowed actions: walk_to (params: x, y), mine_resource (params: resource or resource_name, optional count), no_op (params: {{}}).

Format: {{"action": "walk_to"|"mine_resource"|"no_op", "params": {{...}}}}
- walk_to: use the Suggested follow target (or nearest resource position). Never walk_to the player's exact position.
- mine_resource: when resources list is non-empty, use one resource's "name"; omit count to mine until depleted.
- no_op: ONLY when you are currently busy (state.walking.active, mining, or crafting) OR already within 1 tile of the suggested follow target. Otherwise keep using walk_to toward the suggested follow target."""
            }]
        ranges = self._SENSING_RANGES
        player_ctx = self._player_context_for_llm(agent_state.get("position") if agent_state else None)
        context = f"""## Sensing ranges
{ranges}

## Your position and state
{json.dumps(agent_state, indent=2) if agent_state else "unknown"}

{player_ctx}

## What you can see (within reach)
{json.dumps(reachable, indent=2) if reachable else "{}"}

## Last action result
{last_result if last_result else "First decision."}

Return one action as JSON: {{"action": "...", "params": {{...}}}}"""
        self.npc_contexts[ctx_key].append({"role": "user", "content": context})
        try:
            response = ollama.chat(
                model=self.ollama_model,
                messages=self.npc_contexts[ctx_key],
                format="json",
                options={"temperature": 0.3, "num_predict": 150}
            )
            content = response.get("message", {}).get("content", "").strip()
            # take first line or first {...} in case of extra text
            if "{" in content:
                start = content.index("{")
                end = content.rindex("}") + 1
                content = content[start:end]
            decision = json.loads(content)
            self.npc_contexts[ctx_key].append({"role": "assistant", "content": content})
            if len(self.npc_contexts[ctx_key]) > 9:
                self.npc_contexts[ctx_key] = [self.npc_contexts[ctx_key][0]] + self.npc_contexts[ctx_key][-8:]
            return decision
        except Exception as e:
            print(f"❌ Error querying LLM for action: {e}")
            return None

    def _compute_action_for_mode(self, agent_id: str, mode: str, agent_state: Optional[Dict], reachable: Optional[Dict],
                                  player_position: Optional[Dict], resource: Optional[str], fast: bool) -> tuple:
        """Compute (action, params, is_idle) for one mode without executing. is_idle=True means sequence has nothing to do this tick."""
        if mode == "follow":
            agent_pos = agent_state.get("position") if agent_state and isinstance(agent_state, dict) else None
            suggested = self._suggested_follow_target(agent_pos)
            if suggested is None:
                return (None, {}, True)
            ax = float(agent_pos.get("x", 0)) if agent_pos else 0
            ay = float(agent_pos.get("y", 0)) if agent_pos else 0
            dist = math.sqrt((suggested[0] - ax) ** 2 + (suggested[1] - ay) ** 2)
            if dist <= 1.5:
                return (None, {}, True)  # close enough, follow is "idle"
            return ("walk_to", {"x": int(round(suggested[0])), "y": int(round(suggested[1]))}, False)
        if mode == "mine_all":
            if not resource or not str(resource).strip():
                return (None, {}, True)
            if self.is_agent_busy(agent_id):
                return (None, {}, True)
            resources = (reachable or {}).get("resources") if isinstance(reachable, dict) else []
            if not isinstance(resources, list):
                resources = []
            target = str(resource).strip().lower()
            matching = [r for r in resources if isinstance(r, dict) and (r.get("name") or "").strip().lower() == target]
            if not matching:
                return (None, {}, True)  # nothing to mine in reach
            return ("mine_resource", {"resource": str(resource).strip()}, False)
        return (None, {}, True)

    def run_one_ai_step(self, agent_id: str, mode: str = "follow", last_result: Optional[str] = None, fast: bool = False,
                        resource: Optional[str] = None, try_modes: Optional[List[str]] = None) -> Dict:
        """Run one sense → act cycle. If try_modes is set, try each mode in order; execute first that has work; return active_sequence."""
        out = {"action": None, "params": {}, "result": None, "player_position": None, "active_sequence": None}
        agent_state = self.get_agent_state(agent_id)
        reachable = self.get_reachable_entities(agent_id)
        self.refresh_player_context()
        player_position = (self._last_player_context[0]["position"]) if self._last_player_context else None
        out["player_position"] = player_position

        if try_modes and isinstance(try_modes, list):
            for m in try_modes:
                if m not in ("follow", "mine_all"):
                    continue
                res_var = resource if m == "mine_all" else None
                action, params, is_idle = self._compute_action_for_mode(agent_id, m, agent_state, reachable, player_position, res_var, fast)
                if not is_idle and action:
                    raw = self.execute_action(agent_id, action, params)
                    if raw is True:
                        res = {"success": True, "message": f"{action} executed"}
                    elif isinstance(raw, str):
                        err = ["error", "cannot", "unknown", "failed", "insufficient", "not found"]
                        res = {"success": False, "message": raw} if any(x in raw.lower() for x in err) else {"success": True, "message": raw}
                    else:
                        res = {"success": bool(raw), "message": str(raw)}
                    out["action"] = action
                    out["params"] = params
                    out["result"] = res
                    out["active_sequence"] = m
                    return out
            out["action"] = "no_op"
            out["result"] = {"success": True, "message": "no work (all idle)"}
            return out

        if mode not in ("follow", "mine_all"):
            out["error"] = f"Unsupported mode: {mode}"
            return out

        if mode == "mine_all":
            if not resource or not str(resource).strip():
                out["error"] = "mine_all requires 'resource' (e.g. iron-ore)"
                return out
            if self.is_agent_busy(agent_id):
                out["action"] = "no_op"
                out["result"] = {"success": True, "message": "agent busy"}
                return out
            resources = (reachable or {}).get("resources") if isinstance(reachable, dict) else []
            if not isinstance(resources, list):
                resources = []
            target = str(resource).strip().lower()
            matching = [r for r in resources if isinstance(r, dict) and (r.get("name") or "").strip().lower() == target]
            if not matching:
                out["action"] = "no_op"
                out["result"] = {"success": True, "message": f"no {resource} in reach"}
                return out
            action = "mine_resource"
            params = {"resource": str(resource).strip()}
            raw = self.execute_action(agent_id, action, params)
            if raw is True:
                res = {"success": True, "message": f"{action} executed"}
            elif isinstance(raw, str):
                err = ["error", "cannot", "unknown", "failed", "insufficient", "not found"]
                res = {"success": False, "message": raw} if any(x in raw.lower() for x in err) else {"success": True, "message": raw}
            else:
                res = {"success": bool(raw), "message": str(raw)}
            out["action"] = action
            out["params"] = params
            out["result"] = res
            out["active_sequence"] = "mine_all"
            return out

        # Follow mode
        # Fast follow: skip LLM, just walk toward suggested target (avoids 30–60s Ollama latency per step)
        follow_fast = fast or os.environ.get("FOLLOW_FAST", "").lower() in ("1", "true", "yes")
        if follow_fast:
            agent_pos = agent_state.get("position") if agent_state and isinstance(agent_state, dict) else None
            suggested = self._suggested_follow_target(agent_pos)
            # Fallback: if no suggested (e.g. agent position missing from inspect), use point 5 tiles from player toward origin
            if suggested is None and player_position and isinstance(player_position, dict) and "x" in player_position and "y" in player_position:
                px = float(player_position["x"])
                py = float(player_position["y"])
                d = math.sqrt(px * px + py * py)
                if d > 1e-6:
                    ux, uy = -px / d, -py / d
                    suggested = (px + 5 * ux, py + 5 * uy)
            if suggested is not None:
                ax = float(agent_pos.get("x", 0)) if agent_pos else 0
                ay = float(agent_pos.get("y", 0)) if agent_pos else 0
                dist = math.sqrt((suggested[0] - ax) ** 2 + (suggested[1] - ay) ** 2)
                # Walk whenever we're >1.5 tiles from target (don't rely on is_agent_busy; stuck state can block forever)
                if dist > 1.5:
                    decision = {"action": "walk_to", "params": {"x": int(round(suggested[0])), "y": int(round(suggested[1]))}}
                else:
                    decision = {"action": "no_op", "params": {}}
            else:
                decision = {"action": "no_op", "params": {}}
        else:
            decision = self.query_llm_for_action(agent_id, agent_state, reachable, player_position, last_result)
        if not decision or not decision.get("action"):
            out["result"] = {"success": True, "message": "no decision"}
            return out
        action = (decision.get("action") or "").strip().lower()
        params = decision.get("params") or {}
        suggested = self._suggested_follow_target(agent_state.get("position") if agent_state else None)
        # In follow mode, always use computed follow target for walk_to (LLM often returns agent's own position)
        if action == "walk_to" and suggested is not None:
            params = {"x": int(round(suggested[0])), "y": int(round(suggested[1]))}
        # Guardrail: if LLM said no_op but agent isn't busy and is far from follow target, walk toward target
        elif action == "no_op" and not self.is_agent_busy(agent_id) and suggested is not None and agent_state and "position" in agent_state:
            ax = float(agent_state["position"].get("x", 0))
            ay = float(agent_state["position"].get("y", 0))
            dist = math.sqrt((suggested[0] - ax) ** 2 + (suggested[1] - ay) ** 2)
            if dist > 1.5:
                action = "walk_to"
                params = {"x": int(round(suggested[0])), "y": int(round(suggested[1]))}
        if action == "no_op":
            out["action"] = "no_op"
            out["result"] = {"success": True, "message": "no_op"}
            return out
        raw = self.execute_action(agent_id, action, params)
        if raw is True:
            res = {"success": True, "message": f"{action} executed"}
        elif isinstance(raw, str):
            err = ["error", "cannot", "unknown", "failed", "insufficient", "not found"]
            res = {"success": False, "message": raw} if any(x in raw.lower() for x in err) else {"success": True, "message": raw}
        else:
            res = {"success": bool(raw), "message": str(raw)}
        out["action"] = action
        out["params"] = params
        out["result"] = res
        out["active_sequence"] = "follow"
        return out

    def run_npc_loop(self, agent_id: str):
        """Main loop: get state → ask LLM → trigger n8n → report result."""
        print(f"Starting n8n-based control loop for agent {agent_id}")
        
        last_result = None
        
        while True:
            try:
                # Check if agent is busy
                if self.is_agent_busy(agent_id):
                    time.sleep(1)
                    continue
                
                # Get game state
                agent_state = self.get_agent_state(agent_id)
                reachable = self.get_reachable_entities(agent_id)
                
                # Ask LLM which workflow to run
                decision = self.query_llm_for_workflow(agent_id, "", agent_state, reachable, last_result)
                
                if decision and 'workflow' in decision:
                    workflow_name = decision['workflow']
                    params = decision.get('params', {})
                    
                    print(f"LLM chose workflow: {workflow_name} with params: {params}")
                    
                    # Trigger n8n workflow
                    result = self.trigger_n8n_workflow(workflow_name, agent_id, params)
                    
                    if result.get('success'):
                        last_result = f"Workflow {workflow_name} completed: {result.get('message')}"
                    else:
                        last_result = f"Workflow {workflow_name} failed: {result.get('message')}"
                    
                    print(f"Workflow result: {last_result}")
                else:
                    # Fallback
                    print("⚠️  No valid workflow decision, using fallback")
                    result = self.trigger_n8n_workflow("patrol", agent_id, {'center': {'x': 0, 'y': 0}, 'radius': 50})
                    last_result = f"Fallback patrol: {result.get('message')}"
                
                time.sleep(0.5)
                
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error in control loop: {e}")
                import traceback
                traceback.print_exc()
                time.sleep(1)
    
    # Copy essential methods from FactorioNPCController
    def list_agents(self) -> List[str]:
        """List all existing agent IDs."""
        # Ensure RCON is connected
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return []
        
        existing = []
        for i in range(1, 11):
            agent_id = str(i)
            try:
                command = f"/sc local result = remote.call('agent_{agent_id}', 'inspect', false); return result ~= nil"
                response = self.factorio.send_command(command)
                if response and ("true" in str(response).lower() or "nil" not in str(response).lower()):
                    check_cmd = f"/sc if remote.interfaces.agent_{agent_id} then return 'exists' else return 'missing' end"
                    check_response = self.factorio.send_command(check_cmd)
                    if check_response and "exists" in str(check_response).lower():
                        existing.append(agent_id)
            except:
                continue
        
        # Also try official API
        try:
            command = "/sc return remote.call('agent', 'list_agents')"
            response = self.factorio.send_command(command)
            if response:
                try:
                    data = json.loads(response)
                    if isinstance(data, dict):
                        agent_ids = data.get('agent_ids', [])
                        for id_val in agent_ids:
                            id_str = str(id_val)
                            if id_str not in existing:
                                existing.append(id_str)
                except json.JSONDecodeError:
                    import re
                    ids = re.findall(r'\d+', response)
                    for id_val in ids:
                        if id_val not in existing:
                            existing.append(id_val)
        except:
            pass
        
        return existing
    
    def create_npc(self) -> Optional[str]:
        """Create a new NPC agent."""
        # Ensure RCON is connected
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return None
        
        try:
            command = "/sc return remote.call('agent', 'create_agents', 1)"
            response = self.factorio.send_command(command)
            agent_id = "1"  # Simplified - should parse from response
            
            try:
                from redshirt_names import get_redshirt_name
                redshirt_name = get_redshirt_name(self.agent_counter)
                self.agent_counter += 1
            except ImportError:
                redshirt_name = f"Redshirt_{self.agent_counter}"
                self.agent_counter += 1
            
            self.npc_contexts[agent_id] = []
            print(f"Created NPC: {redshirt_name} (agent_{agent_id})")
            return agent_id
        except Exception as e:
            print(f"Error creating NPC: {e}")
            return None
    
    def get_agent_state(self, agent_id: str) -> Optional[Dict]:
        """Get agent state. Uses rcon.print(helpers.table_to_json(...)) so RCON client receives output."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return {"_raw": "(no rcon)", "_note": "controller not connected"}
        command = (
            f"/sc local r = remote.call('agent_{agent_id}', 'inspect', true); "
            "if rcon then rcon.print(r and helpers.table_to_json(r) or 'null') end"
        )
        try:
            response = self.factorio.send_command(command)
            raw = (response or "").strip()
            if not raw:
                return {"_raw": "(empty)", "_note": "RCON returned nothing"}
            try:
                out = json.loads(raw)
                if isinstance(out, dict):
                    out["_raw"] = raw
                return out
            except json.JSONDecodeError:
                return {"_raw": raw, "_note": "json decode failed"}
        except Exception as e:
            return {"_raw": "(exception)", "_note": str(e)}
    
    def is_agent_busy(self, agent_id: str) -> bool:
        """Check if agent is busy."""
        agent_state = self.get_agent_state(agent_id)
        if not agent_state or not isinstance(agent_state, dict):
            return False
        
        state = agent_state.get('state', {})
        if not isinstance(state, dict):
            return False
        
        walking = state.get('walking', {})
        mining = state.get('mining', {})
        crafting = state.get('crafting', {})
        
        if isinstance(walking, dict) and (walking.get('active', False) or walking.get('goal')):
            return True
        if isinstance(mining, dict) and mining.get('active', False):
            return True
        if isinstance(crafting, dict):
            if crafting.get('active', False):
                return True
            queue = crafting.get('queue', [])
            if queue and len(queue) > 0:
                return True
        
        return False
    
    def get_constructed_entities(self, agent_id: str) -> List[Dict]:
        """Get constructed entities (simplified version)."""
        # Simplified - just use get_reachable and filter
        reachable = self.get_reachable_entities(agent_id)
        if reachable and isinstance(reachable, dict):
            entities = reachable.get('entities', [])
            # Filter to constructed entities
            constructed = []
            for entity in entities:
                name = str(entity.get('name', '')).lower()
                if any(kw in name for kw in ['chest', 'assembling', 'furnace', 'belt', 'rail', 'inserter', 'container', 'lab', 'boiler', 'pump', 'pipe', 'mining', 'drill', 'wall', 'turret', 'radar', 'lamp', 'pole']):
                    constructed.append(entity)
            return constructed
        return []
    
    def calculate_distance(self, pos1: tuple, pos2: tuple) -> float:
        """Calculate distance between two positions."""
        return math.sqrt((pos1[0] - pos2[0])**2 + (pos1[1] - pos2[1])**2)
    
    def get_player_position(self) -> Optional[Dict]:
        """Position of first connected player's character. None if no player or no character."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return None
        command = (
            "/sc local out = nil; "
            "for _, p in pairs(game.connected_players) do "
            "  if p.character then local pos = p.character.position; out = {x = pos.x, y = pos.y}; break; end "
            "end; "
            "if rcon then if out then rcon.print(string.format('{\"x\":%f,\"y\":%f}', out.x, out.y)) else rcon.print('null') end end"
        )
        try:
            response = self.factorio.send_command(command)
            raw = (response or "").strip()
            if not raw or raw == "null":
                return None
            out = json.loads(raw)
            if isinstance(out, dict) and "x" in out and "y" in out:
                return {"x": float(out["x"]), "y": float(out["y"])}
            return None
        except Exception:
            return None

    def get_players(self) -> List[Dict]:
        """All connected players with characters. Returns [{name, position}, ...]. Used for tracking."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return []
        # Lua: one line per player "x,y,name" so name can contain commas
        command = (
            "/sc local lines = {}; "
            "for _, p in pairs(game.connected_players) do "
            "  if p.character then local pos = p.character.position; "
            "    lines[#lines+1] = tostring(pos.x) .. ',' .. tostring(pos.y) .. ',' .. (p.name or '?'); end "
            "end; "
            "if rcon then rcon.print(table.concat(lines, '\\n')) end"
        )
        try:
            response = self.factorio.send_command(command)
            raw = (response or "").strip()
            if not raw:
                return []
            out = []
            for line in raw.split("\n"):
                line = line.strip()
                if not line:
                    continue
                parts = line.split(",", 2)
                if len(parts) >= 3:
                    try:
                        out.append({
                            "position": {"x": float(parts[0]), "y": float(parts[1])},
                            "name": parts[2].strip()
                        })
                    except (ValueError, TypeError):
                        continue
            return out
        except Exception:
            return []

    def refresh_player_context(self) -> List[Dict]:
        """Refresh and return current player list. Call before every LLM prompt. Injected into every prompt."""
        self._last_player_context = self.get_players()
        return self._last_player_context

    def _player_context_for_llm(self, agent_position: Optional[Dict], players: Optional[List[Dict]] = None) -> str:
        """Formatted player context for prompts: positions, 5-tile rule, suggested follow target."""
        players = players if players is not None else self._last_player_context
        min_tiles = getattr(self, "_follow_min_tiles", 5)
        if not players:
            return "## Player context\nNo connected players."
        lines = [f"## Player context\nRule: Do not come closer than {min_tiles} tiles to any player."]
        for i, p in enumerate(players):
            pos = p.get("position") if isinstance(p, dict) else None
            name = p.get("name", "player") if isinstance(p, dict) else "player"
            if pos and "x" in pos and "y" in pos:
                lines.append(f"Player {name}: ({pos['x']:.1f}, {pos['y']:.1f})")
        # Suggested follow target: point min_tiles from nearest player toward agent
        if agent_position and "x" in agent_position and "y" in agent_position and players:
            ax = float(agent_position["x"])
            ay = float(agent_position["y"])
            best = None
            best_d = None
            for p in players:
                pos = p.get("position") if isinstance(p, dict) else None
                if not pos or "x" not in pos or "y" not in pos:
                    continue
                px, py = float(pos["x"]), float(pos["y"])
                d = math.sqrt((px - ax) ** 2 + (py - ay) ** 2)
                if best_d is None or d < best_d:
                    best_d, best = d, (px, py)
            if best is not None and best_d is not None:
                px, py = best
                if best_d > 1e-6:
                    # unit from agent to player
                    ux = (px - ax) / best_d
                    uy = (py - ay) / best_d
                    # target = position min_tiles from player toward agent
                    tx = px + min_tiles * (-ux)
                    ty = py + min_tiles * (-uy)
                    lines.append(f"Suggested follow target (stay {min_tiles} tiles from player): ({tx:.1f}, {ty:.1f}). Use walk_to with this target.")
                else:
                    lines.append("Agent is very close to player; do not walk closer.")
        return "\n".join(lines)

    def _suggested_follow_target(self, agent_position: Optional[Dict], players: Optional[List[Dict]] = None) -> Optional[tuple]:
        """Return (x, y) of the point min_tiles from nearest player toward agent, or None."""
        players = players if players is not None else self._last_player_context
        min_tiles = getattr(self, "_follow_min_tiles", 5)
        if not agent_position or "x" not in agent_position or "y" not in agent_position or not players:
            return None
        ax = float(agent_position["x"])
        ay = float(agent_position["y"])
        best_d = None
        best_player = None
        for p in players:
            pos = p.get("position") if isinstance(p, dict) else None
            if not pos or "x" not in pos or "y" not in pos:
                continue
            px, py = float(pos["x"]), float(pos["y"])
            d = math.sqrt((px - ax) ** 2 + (py - ay) ** 2)
            if best_d is None or d < best_d:
                best_d, best_player = d, (px, py)
        if best_player is None or best_d is None or best_d < 1e-6:
            return None
        px, py = best_player
        ux = (px - ax) / best_d
        uy = (py - ay) / best_d
        tx = px + min_tiles * (-ux)
        ty = py + min_tiles * (-uy)
        return (tx, ty)

    def get_reachable_entities(self, agent_id: str) -> Optional[Dict]:
        """Get reachable entities. Uses rcon.print(helpers.table_to_json(...)) so RCON client receives output."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return {"_raw": "(no rcon)", "_note": "controller not connected"}
        command = (
            f"/sc local r = remote.call('agent_{agent_id}', 'get_reachable'); "
            "if rcon then rcon.print(r and helpers.table_to_json(r) or 'null') end"
        )
        try:
            response = self.factorio.send_command(command)
            raw = (response or "").strip()
            if not raw:
                return {"_raw": "(empty)", "_note": "RCON returned nothing"}
            try:
                out = json.loads(raw)
                if isinstance(out, dict):
                    out["_raw"] = raw
                return out
            except json.JSONDecodeError:
                return {"_raw": raw, "_note": "json decode failed"}
        except Exception as e:
            return {"_raw": "(exception)", "_note": str(e)}
    
    def get_recipes(self, agent_id: str) -> Optional[Dict]:
        """Get available recipes. Uses rcon.print(helpers.table_to_json(...)) so RCON client receives output."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return {"_raw": "(no rcon)", "_note": "controller not connected"}
        command = (
            f"/sc local r = remote.call('agent_{agent_id}', 'get_recipes'); "
            "if rcon then rcon.print(r and helpers.table_to_json(r) or 'null') end"
        )
        try:
            response = self.factorio.send_command(command)
            raw = (response or "").strip()
            if not raw:
                return {"_raw": "(empty)", "_note": "RCON returned nothing"}
            try:
                out = json.loads(raw)
                if isinstance(out, dict):
                    out["_raw"] = raw
                return out
            except json.JSONDecodeError:
                return {"_raw": raw, "_note": "json decode failed"}
        except Exception as e:
            return {"_raw": "(exception)", "_note": str(e)}
    
    def get_technologies(self, agent_id: str, researched_only: bool = False) -> Optional[Dict]:
        """Get technologies. Uses rcon.print(helpers.table_to_json(...)) so RCON client receives output."""
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return {"_raw": "(no rcon)", "_note": "controller not connected"}
        lua_bool = "true" if researched_only else "false"
        cmd = (
            f"/sc local r = remote.call('agent_{agent_id}', 'get_technologies', {lua_bool}); "
            "if rcon then rcon.print(r and helpers.table_to_json(r) or 'null') end"
        )
        try:
            response = self.factorio.send_command(cmd)
            raw = (response or "").strip()
            if not raw:
                return {"_raw": "(empty)", "_note": "RCON returned nothing"}
            try:
                out = json.loads(raw)
                if isinstance(out, dict):
                    out["_raw"] = raw
                return out
            except json.JSONDecodeError:
                return {"_raw": raw, "_note": "json decode failed"}
        except Exception as e:
            return {"_raw": "(exception)", "_note": str(e)}
    
    def execute_action(self, agent_id: str, action: str, params: Dict):
        """Execute an action via RCON."""
        # Ensure RCON is connected
        if self.factorio is None:
            self._connect_rcon()
        if self.factorio is None:
            return "Error: Could not connect to Factorio RCON server"
        
        try:
            if action == "walk_to":
                x, y = params.get('x', 0), params.get('y', 0)
                # FV mod expects position; use int so we send tile coords (avoids float/format issues)
                xi, yi = int(round(float(x))), int(round(float(y)))
                command = f"/sc remote.call('agent_{agent_id}', 'walk_to', {{x={xi}, y={yi}}})"
            elif action == "mine_resource":
                resource = params.get('resource', params.get('resource_name', ''))
                count = params.get('count')
                if count:
                    command = f"/sc remote.call('agent_{agent_id}', 'mine_resource', '{resource}', {count})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'mine_resource', '{resource}')"
            elif action == "place_entity":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                command = f"/sc remote.call('agent_{agent_id}', 'place_entity', '{entity}', {{x={x}, y={y}}})"
            elif action == "set_inventory_item":
                entity = params.get('entity', 'wooden-chest')
                x, y = params.get('x', 0), params.get('y', 0)
                inventory = params.get('inventory', 'chest')
                item = params.get('item', '')
                count = params.get('count', 0)
                if count > 0:
                    command = f"/sc remote.call('agent_{agent_id}', 'set_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}', {count})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'set_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}')"
            elif action == "craft_enqueue":
                recipe = params.get('recipe', params.get('recipe_name', ''))
                count = params.get('count')
                if count:
                    command = f"/sc remote.call('agent_{agent_id}', 'craft_enqueue', '{recipe}', {count})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'craft_enqueue', '{recipe}')"
            elif action == "set_entity_recipe":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                recipe = params.get('recipe', params.get('recipe_name', ''))
                command = f"/sc remote.call('agent_{agent_id}', 'set_entity_recipe', '{entity}', {{x={x}, y={y}}}, '{recipe}')"
            elif action == "get_inventory_item":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                inventory = params.get('inventory', 'chest')
                item = params.get('item', '')
                count = params.get('count', 0)
                if count > 0:
                    command = f"/sc remote.call('agent_{agent_id}', 'get_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}', {count})"
                else:
                    command = f"/sc remote.call('agent_{agent_id}', 'get_inventory_item', '{entity}', {{x={x}, y={y}}}, '{inventory}', '{item}')"
            elif action == "set_entity_filter":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                filter_type = params.get('filter_type', 'inserter_stack_filter')
                filter_index = params.get('filter_index', 1)
                item = params.get('item', '')
                command = f"/sc remote.call('agent_{agent_id}', 'set_entity_filter', '{entity}', {{x={x}, y={y}}}, '{filter_type}', {filter_index}, '{item}')"
            elif action == "set_inventory_limit":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                inventory = params.get('inventory', 'chest')
                limit = params.get('limit', 10)
                command = f"/sc remote.call('agent_{agent_id}', 'set_inventory_limit', '{entity}', {{x={x}, y={y}}}, '{inventory}', {limit})"
            elif action == "pickup_entity":
                entity = params.get('entity', params.get('entity_name', ''))
                x, y = params.get('x', 0), params.get('y', 0)
                command = f"/sc remote.call('agent_{agent_id}', 'pickup_entity', '{entity}', {{x={x}, y={y}}})"
            elif action == "enqueue_research":
                technology = params.get('technology', params.get('tech_name', ''))
                command = f"/sc remote.call('agent_{agent_id}', 'enqueue_research', '{technology}')"
            elif action == "cancel_current_research":
                command = f"/sc remote.call('agent_{agent_id}', 'cancel_current_research')"
            elif action == "chart_view":
                rechart = params.get('rechart', False)
                command = f"/sc remote.call('agent_{agent_id}', 'chart_view', {str(rechart).lower()})"
            else:
                return f"Unknown action: {action}"
            
            response = self.factorio.send_command(command)
            if response and isinstance(response, str):
                if "error" in response.lower() or "cannot" in response.lower():
                    return f"Action '{action}' failed: {response}"
                else:
                    return f"Action '{action}' succeeded: {response}"
            return True
        except Exception as e:
            return f"Error executing action {action}: {e}"
    
    def close(self):
        """Cleanup."""
        if self.http_server:
            self.http_server.shutdown()
        
        if self.ollama_process and self.ollama_started_by_us:
            self.ollama_process.terminate()


def main():
    """Main entry point."""
    print("="*70)
    print("Factorio HTTP Controller")
    print("="*70)
    
    controller = FactorioN8NController(
        rcon_host=RCON_HOST,
        rcon_port=RCON_PORT,
        rcon_password=RCON_PASSWORD,
        ollama_model=OLLAMA_MODEL,
        ollama_host=OLLAMA_HOST,
        ollama_port=OLLAMA_PORT,
    )
    
    # HTTP server is started in __init__, just keep it running
    print(f"\n✅ Controller ready!")
    print(f"   - HTTP server: http://localhost:8080")
    print(f"   - RCON: {RCON_HOST}:{RCON_PORT}")
    print(f"   - Ollama: {OLLAMA_HOST}:{OLLAMA_PORT} (set OLLAMA_HOST/OLLAMA_PORT to reach remote Ollama)")
    if getattr(controller, "_ref_data_dir", None):
        print(f"   - Reference data: {os.path.abspath(controller._ref_data_dir)}")
    print(f"\nHTTP server running. Waiting for requests...")
    print("(Press Ctrl+C to stop)\n")
    
    # Keep the process alive to serve HTTP requests
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        controller.close()


if __name__ == "__main__":
    main()
