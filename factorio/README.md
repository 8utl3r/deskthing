# Factorio AI NPC System

LLM-controlled NPCs in Factorio using Ollama and the FV Embodied Agent mod.

---

## What’s What (Two “Controllers”)

| What | File | Where it runs | Purpose |
|------|------|----------------|---------|
| **Ollama controller** | `factorio_ollama_npc_controller.py` | **Local Mac** | Main NPC loop: Ollama + RCON. Run via `./run_controller.sh` or `python3 factorio_ollama_npc_controller.py`. |
| **HTTP controller** | `factorio_http_controller.py` | **NAS** (TrueNAS app) or locally | HTTP API on :8080 for `agent_scripts/`: health, inspect, get-reachable, execute-action, reference data. Name “n8n” is legacy; n8n workflows are not used. |

**agent_scripts/** talk to the **HTTP controller** (`CONTROLLER_URL=http://...:8080`). The **Ollama controller** is the main script you run locally for NPC behaviour.

---

## Architecture

```
Local Mac                          TrueNAS NAS
├── Ollama (LLM)                   ├── Factorio Server (Docker)
├── Ollama controller               │   ├── FV Embodied Agent Mod
│   (factorio_ollama_npc_controller)│   └── RCON enabled (port 27015)
└── Connects via RCON ────────────▶│
                                   ├── HTTP controller (:8080)  ← agent_scripts use this
                                   │   (factorio_http_controller)
```

---

## Directory Layout (After Cleanup)

- **Base:** README, START_HERE, config, requirements, both controllers, run_controller.sh, verify_rcon_password.py, CONTROLLER_API_REFERENCE, directive_agent_design, nas_setup_guide, connection_verification_flow, verify_connections.sh, push_controller_to_nas.sh, truenas_controller_app_volume.yaml, truenas_custom_app.yaml, fv_embodied_agent_api_guide. Docker/build/deploy scripts and alternate YAMLs are in **archive/** (see archive/README.md).
- **agent_scripts/** – Scripts that call the HTTP controller (see agent_scripts/README.md).
- **docs/** – Design and cleanup notes: docs/INVENTORY_AND_CLEANUP.md; docs/archive/ has older design/troubleshooting docs.
- **archive/** – Zombie/duplicate files (n8n, old deploy/quick-start docs, network one-offs). See archive/README.md. Not deleted; kept for reference.

---

## Quick Start

### 1. Prerequisites

- ✅ Ollama installed and running (on Mac)
- ✅ Python 3.8+ with dependencies installed
- ✅ TrueNAS NAS with Apps enabled
- ✅ Network access to NAS

### 2. Install Python Dependencies

```bash
cd /Users/pete/dotfiles/factorio
pip install -r requirements.txt
```

### 3. Pull Ollama Model

```bash
# Recommended for NPCs (fast decision-making):
ollama pull mistral         # Fast and efficient (7B) - RECOMMENDED
# Or:
ollama pull qwen2.5:7b      # Good reasoning (7B)
ollama pull phi3:medium     # Smallest, fastest (3.8B)
ollama pull llama3.1        # Better decisions but slower (8B)
```

### 4. Set Up Factorio on NAS

Follow the detailed guide: **[nas_setup_guide.md](nas_setup_guide.md)**

Quick summary:
1. Install Factorio via TrueNAS Custom App (see `truenas_custom_app.yaml`)
2. Install FV Embodied Agent mod
3. Configure RCON password
4. Test RCON connection

### 5. Configure Controller

Edit `config.py`:
```python
RCON_HOST = "192.168.0.158"  # Your NAS IP
RCON_PASSWORD = "your_password_here"
OLLAMA_MODEL = "llama3.1"
```

### 6. Run Controller

```bash
python3 factorio_ollama_npc_controller.py
```

## Key Files (Base Dir)

- `factorio_ollama_npc_controller.py` – **Ollama controller** (main NPC loop; run locally). Depends on `workflows.py`.
- `factorio_http_controller.py` – **HTTP controller** (serves :8080; runs on NAS or locally for agent_scripts).
- `workflows.py` – NPC workflow definitions; required by the Ollama controller.
- `config.py` – Configuration (edit this!).
- `requirements.txt` – Python dependencies.
- `run_controller.sh` – Runs the Ollama controller after checks.
- `verify_rcon_password.py` – RCON connectivity check.
- `nas_setup_guide.md` – NAS/Factorio setup.
- `CONTROLLER_API_REFERENCE.md` – HTTP API used by agent_scripts.
- `CONTROLLER_ON_NAS.md` – How to run the HTTP controller on NAS.
- `connection_verification_flow.md` – Connection checks; run `./verify_connections.sh` for one-shot pass/fail.
- **`directive_agent_design.md`** – Design for directive-driven agents (queues, Qdrant, phased plan).

Older design/setup docs (factorio_ollama_setup, feature charts, etc.) are in **docs/archive/**; zombie/duplicate docs (n8n, old deploy guides) are in **archive/**. See **docs/INVENTORY_AND_CLEANUP.md** for the full list.

## Agent scripts (HTTP controller clients)

**`agent_scripts/`** – Scripts that call the **HTTP controller** at `CONTROLLER_URL` (e.g. `http://192.168.0.158:8080`). Develop on your Mac, test against the NAS HTTP controller, then deploy when ready. See **[agent_scripts/README.md](agent_scripts/README.md)** for setup, `controller_client.py`, and deploy steps.

## Usage Examples

### Create Multiple NPCs

```python
from factorio_ollama_npc_controller import FactorioNPCController
import threading

controller = FactorioNPCController(
    rcon_host="192.168.0.158",
    rcon_port=27015,
    rcon_password="your_password",
    ollama_model="llama3.1"
)

# Create NPCs
controller.create_npc("miner_bob", position=(10, 10))
controller.create_npc("builder_alice", position=(20, 20))

# Run control loops in separate threads
threading.Thread(target=controller.run_npc_loop, args=("miner_bob", 5.0)).start()
threading.Thread(target=controller.run_npc_loop, args=("builder_alice", 5.0)).start()
```

## Troubleshooting

### RCON Connection Failed
- Check NAS IP in `config.py`
- Verify Factorio container is running on NAS
- Check firewall allows port 27015 TCP

### Ollama Connection Failed
- Verify Ollama is running: `ollama list`
- Check model is pulled: `ollama list | grep llama3.1`

### NPC Not Responding
- Check Factorio console for errors
- Verify FV Embodied Agent mod is enabled
- Check RCON command responses in controller output

## Resources

- **FV Embodied Agent Mod**: https://mods.factorio.com/mod/fv_embodied_agent
- **Factorio Lua API**: https://lua-api.factorio.com/
- **Ollama**: https://ollama.com/
- **Factorio Docker Image**: https://hub.docker.com/r/goofball222/factorio
