# Factorio Directory: Inventory and Cleanup

**Date:** 2025-01-24  
**Purpose:** Clarify what’s active vs zombie, then clean and organize the factorio tree.

---

## What’s Actually In Use

### 1. Two “Controllers” (Confusing Name)

| File | Role | Where it runs | Referenced by |
|------|------|----------------|---------------|
| **factorio_ollama_npc_controller.py** | Main NPC loop: Ollama + RCON, runs agents. | **Local Mac** (e.g. `./run_controller.sh` → runs this). | README, START_HERE, run_controller.sh |
| **factorio_http_controller.py** | HTTP + RCON bridge. Serves :8080 (health, inspect, get-reachable, execute-action, reference data). | **NAS** (TrueNAS app) or locally. | agent_scripts (CONTROLLER_URL), push_controller_to_nas.sh, truenas_controller_app*.yaml |

So: **Ollama controller** = “main” script you run locally. **“n8n” controller** = HTTP API on :8080; the name is legacy (n8n workflows are unused). Agent_scripts talk to the HTTP controller.

### 2. Active Code and Config (Keep in Tree)

- **factorio_ollama_npc_controller.py** – main NPC loop (depends on **workflows.py**)
- **factorio_n8n_controller.py** – HTTP API used by agent_scripts (rename optional later)
- **workflows.py** – NPC workflow definitions; required by Ollama controller (was archived, restored 2025-01-24)
- **config.py**, **requirements.txt**
- **run_controller.sh** – runs Ollama controller
- **verify_rcon_password.py** – RCON check
- **agent_scripts/** – all of it (controller_client, sense_*, verify_*, etc.)
- **redshirt_names.py** – used by a controller

### 3. Active Docs (Keep Easy to Find)

- **README.md** – main entry; should describe both controllers and layout
- **START_HERE.md** – run path (Ollama + RCON)
- **CONTROLLER_API_REFERENCE.md** – HTTP API (for agent_scripts and HTTP controller)
- **directive_agent_design.md** – design for directive-driven agents
- **fv_embodied_agent_api_guide.md** – FV mod API
- **nas_setup_guide.md** – NAS/Factorio setup
- **connection_verification_flow.md** – connection checks
- **verify_connections.sh** – script for those checks

### 4. Active Deployment / TrueNAS

- **push_controller_to_nas.sh** – deploys HTTP controller (factorio_http_controller.py) to NAS
- **truenas_controller_app_volume.yaml** or **truenas_controller_app.yaml** – one canonical TrueNAS app def for the HTTP controller
- **CONTROLLER_ON_NAS.md** – how the HTTP controller runs on NAS (keep one deploy doc)

### 5. Zombie / Legacy (Archive)

- **n8n_workflows/** – n8n workflows no longer used
- **N8N_*.md** – N8N_ARCHITECTURE, N8N_SETUP_GUIDE, N8N_NETWORK_*, N8N_APP_*, N8N_MIGRATION_*, ENABLE_N8N_*, FIX_N8N_*, FIND_HOST_NETWORK_FOR_CATALOG_APP, WORKFLOW_ARCHITECTURE (n8n-focused)
- **workflows.py**, **test_workflow_actions.py** – workflow/n8n-related
- **com.pete.factorio-n8n-controller.plist** – launchd name is legacy; keep only if you still use it to run the HTTP controller

### 6. Duplicate / Superseded Docs (Archive)

- **CONTROLLER_TEST_REPORT.md**, **CONTROLLER_TEST_SUMMARY.md** – one-off test notes
- **CONTROLLER_DEPLOY.md**, **CONTROLLER_DEPLOYMENT_GUIDE.md**, **CONTROLLER_UPDATE_OPTIONS.md**
- **DEPLOY_CONTROLLER_TO_NAS.md**, **DEPLOY_CONTROLLER_TO_NAS_NOW.md**, **DEPLOYMENT_CHECKLIST.md**, **COMPLETE_DEPLOYMENT_PLAN.md** – fold into one “Deploy HTTP controller to NAS” doc, archive rest
- **QUICK_RUN.md**, **QUICK_START.md**, **READY_TO_RUN.md**, **WALKTHROUGH.md** – duplicate “how to run”; keep START_HERE + README, archive rest

### 7. Extra TrueNAS / Network / One-Off (Archive or docs/)

- **truenas_custom_app_*.yaml** (many variants) – keep one canonical Factorio app YAML; archive the “fix”/“host_network”/“no_healthcheck” variants
- **NETWORK_*.md**, **connection_fix_steps**, **host_network_fix_guide**, **same_network_troubleshooting**, **network_connection_troubleshooting**, **NETWORK_FIX_***, **shell_fix_*** – move to **docs/archive/** or **docs/troubleshooting/** so base stays minimal
- **create_fast_pool_guide**, **partition_nvme_***, **fast_pool_rescue**, **FIND_HOST_NETWORK_SETTING**, **FIXES_APPLIED**, **catalog_vs_custom** – one-off or NAS generic → **docs/archive/**

### 8. Other Doc / Scripts

- **instruction_improvements_summary**, **llm_instruction_analysis**, **llm_system_prompt**, **priority_implementation_summary**, **MODEL_RECOMMENDATIONS**, **factorio_ollama_setup**, **factorio_ollama_npc_implementation_summary**, **factorio_ai_automation_feature_matrix**, **existing_work_slot_in_guide**, **feature_charts_by_component** – keep in **docs/** (or **docs/design/**) so README stays short
- **DEBUGGING_*.md**, **troubleshooting.md**, **MISSING_ACTIONS** – **docs/** or **docs/troubleshooting/**
- Shell scripts (sync_mods, verify_connections, test_connection, etc.) – keep in root or **scripts/** depending on count; if many, **scripts/**

---

## Layout After Cleanup

```
factorio/
├── README.md                    # Single entry: what’s what, quick start, pointer to docs
├── START_HERE.md                # Run path (Ollama controller)
├── config.py
├── requirements.txt
├── run_controller.sh
├── verify_rcon_password.py
├── factorio_ollama_npc_controller.py
├── factorio_http_controller.py
├── workflows.py                 # required by Ollama controller
├── redshirt_names.py
├── CONTROLLER_API_REFERENCE.md
├── directive_agent_design.md
├── nas_setup_guide.md
├── connection_verification_flow.md
├── verify_connections.sh
├── push_controller_to_nas.sh
├── truenas_controller_app_volume.yaml  # or truenas_controller_app.yaml – one canonical
├── CONTROLLER_ON_NAS.md         # One “deploy HTTP controller to NAS” doc
├── agent_scripts/
├── docs/                        # Design, troubleshooting, deep dives
│   ├── INVENTORY_AND_CLEANUP.md (this file)
│   ├── design/                 # optional
│   └── archive/                # superseded / zombie
└── archive/                     # Zombie + duplicate docs + old variants
    ├── n8n_workflows/
    ├── N8N_*.md
    ├── CONTROLLER_TEST_*.md, CONTROLLER_DEPLOY*.md, DEPLOY_*.md, COMPLETE_DEPLOYMENT_PLAN.md
    ├── QUICK_*.md, READY_TO_RUN.md, WALKTHROUGH.md
    ├── truenas_custom_app_* (all but one), truenas_controller_app.yaml (if volume is canonical)
    └── … (see sections 5–7 above)
```

---

## Rules Used

- **File versioning:** “Move outdated content to archive folder, don’t delete.”
- **Single source of truth:** One run path (README + START_HERE), one HTTP API ref, one deploy-to-NAS story.
- **Clear naming:** README explains “Ollama controller” vs “HTTP controller” so the n8n name doesn’t confuse.

---

## Done in This Pass (2025-01-24)

1. Created **docs/INVENTORY_AND_CLEANUP.md** (this file) and **archive/README.md**.
2. Created **archive/** and **docs/archive/**. Moved into **archive/**: n8n_workflows/, all N8N_*.md, ENABLE_N8N_*, FIX_N8N_*, FIND_HOST_NETWORK_*, WORKFLOW_ARCHITECTURE.md, workflows.py, test_workflow_actions.py; CONTROLLER_TEST_*, CONTROLLER_DEPLOY*, DEPLOY_*, COMPLETE_DEPLOYMENT_PLAN, DEPLOYMENT_CHECKLIST; QUICK_RUN, QUICK_START, READY_TO_RUN, WALKTHROUGH; NETWORK_*, connection_fix_steps, host_network_fix_guide, same_network_troubleshooting, network_connection_troubleshooting, shell_fix_*; truenas_custom_app variants (kept truenas_custom_app.yaml), n8n_host_network.yaml; create_fast_pool_guide, partition_nvme_*, fast_pool_rescue, FIXES_APPLIED, catalog_vs_custom; deploy_controller_script.sh, setup_controller_for_nas.sh; manual_udp_fix, quick_udp_fix, update_factorio_dns, watch_dns_update, troubleshoot_external_connection, step_by_step_partitioning, setup_boot_pool_directory; test_admin_interface, test_connections, test_dynamic_dns, test_mod_direct, test_rcon_tools; cloudflare_*, dynamic_dns_*, force_dns_*, secure_external_*, udm_pro_*, truenas_udp_issue, udp_port_troubleshooting; API_SUMMARY, check_mod_version_issue, mod_management_guide, SERVICE_SETUP. Moved into **docs/archive/**: ARCHITECTURE_OPTIONS, build_and_deploy_guide, DEBUGGING_*, instruction_improvements_summary, llm_*, priority_implementation_summary, MODEL_RECOMMENDATIONS, factorio_ollama_setup, factorio_ollama_npc_implementation_summary, factorio_ai_automation_feature_matrix, existing_work_slot_in_guide, feature_charts_by_component, MISSING_ACTIONS, troubleshooting, version_update_options, update_factorio_version, fix_version_mismatch, agent_priority_system; cloudflare_*, dynamic_dns_*, etc. (DNS/network one-offs).
3. Updated **README.md** with “What’s what” (Ollama controller vs HTTP controller), architecture diagram, directory layout, and key files. Updated **connection_verification_flow.md** to note that n8n is not used.
4. Base dir now has ~40 top-level files; zombie/duplicate content is in **archive/** and **docs/archive/**.
5. **Base-dir trim:** Moved to **archive/**: build_controller_image.sh, build_docker_image.sh, deploy_controller_to_nas.sh, Dockerfile, Dockerfile.controller, docker-compose.controller.yml, docker_compose_setup.sh; check_mod_enabled.sh, check_mod_interface.py, check_rcon_password.sh, find_rcon_password.sh, get_rcon_password.sh, enable_mod.sh, monitor_factorio.sh, restart_factorio_container.sh, setup_service.sh, sync_mods.sh, test_connection.sh; debug_agent_state.py; com.pete.factorio-n8n-controller.plist; truenas_controller_app.yaml. Base now matches the “Layout After Cleanup” tree (README, START_HERE, config, requirements, run_controller.sh, verify_rcon_password.py, both controllers, redshirt_names, CONTROLLER_API_REFERENCE, directive_agent_design, nas_setup_guide, connection_verification_flow, verify_connections.sh, push_controller_to_nas.sh, truenas_controller_app_volume.yaml, truenas_custom_app.yaml, CONTROLLER_ON_NAS, fv_embodied_agent_api_guide, agent_scripts/, docs/, archive/).
