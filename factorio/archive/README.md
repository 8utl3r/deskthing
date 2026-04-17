# Archived Factorio Docs and Scripts

Files here are **zombie** (unused) or **superseded** (duplicate/older). They were moved during the 2025-01-24 cleanup so the main factorio dir stays clean. See **docs/INVENTORY_AND_CLEANUP.md** for the full list and rules.

**Do not delete** — keep for reference. Restore to the tree only if you need an older variant or n8n-related content.

**Main categories:**
- **n8n_workflows/** and **N8N_*.md** – n8n workflows and setup (no longer used)
- **CONTROLLER_***, **DEPLOY_*** – duplicate deploy/test docs (one canonical version remains in base)
- **QUICK_***, **READY_TO_RUN**, **WALKTHROUGH** – duplicate “how to run” (use README + START_HERE)
- **NETWORK_***, **connection_***, **shell_fix_*** – one-off network/troubleshooting
- **truenas_custom_app_*** variants – kept one canonical app YAML in base
- **workflows.py** – restored to base (Ollama controller depends on it). **test_workflow_actions.py** – workflow/n8n-related, remains in archive.
- **Base-dir trim:** build_*_image.sh, deploy_controller_to_nas.sh, Dockerfile*, docker-compose.controller.yml, docker_compose_setup.sh; check_mod_*, check_rcon_password.sh, find/get_rcon_password.sh, enable_mod.sh, monitor_factorio.sh, restart_factorio_container.sh, setup_service.sh, sync_mods.sh, test_connection.sh; debug_agent_state.py; com.pete.factorio-n8n-controller.plist (restore if running HTTP controller via launchd); truenas_controller_app.yaml (canonical in base: truenas_controller_app_volume.yaml).
