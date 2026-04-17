# Project Context: Dotfiles

## Version History
- 2026-02-16: Authelia TrueNAS tooling (deploy/restart/check/fix-perms/logs), rich dashboard, audit script, and email helper added; deploy preserves existing users file unless `USERS_FILE` set; config path validated at `/config`, Argon2 hash required.
- 2026-02-13: Cua (Computer-Use Agent) MCP server added to Cursor; setup documented in `docs/services/cua-cursor-setup.md`.
- 2026-02-08: Audible/Kindle → LazyLibrarian: audible-cli installed, script supports Kindle-only mode, kindle-export-console.js and requirements.txt added.
- 2026-01-20: Moved historical session records to `docs/session_records_index.md`.

## Overview
Personal dotfiles repository for macOS system configuration and development environment setup. Focuses on reproducible, non-destructive configuration management.

## Architecture Summary
- **Configuration Management**: Symlink-based system with dry-run defaults and backup capabilities
- **Package Management**: Curated Brewfile with manual installation process
- **System Integration**: macOS defaults, Alfred workflows, Cursor IDE settings, ActiveDock 2
- **Shell Environment**: Zsh with Starship prompt, mise for runtime management
- **Window Management**: Hammerspoon and Karabiner for keyboard customization

## Current State
- Repository: `/Users/pete/dotfiles`
- Git Status: 17 commits ahead of origin/main
- Modified Files: `aerospace/aerospace.toml`, `hammerspoon/init.lua`, `karabiner/karabiner.json`
- Key Scripts: `scripts/system/link` (symlinks), `scripts/system/bootstrap` (setup), `scripts/system/snapshot` (inventory)

## Session Records

### 2026-02-13 - Cua MCP server (Cursor computer-use agent)
- **Date/Time:** 2026-02-13
- **Objective:** Add Cua Computer-Use Agent MCP server so Cursor agents can run computer-use workflows in an isolated macOS sandbox.
- **Actions Taken:** Added `cua` entry to `cursor/mcp.json` (official one-liner install; script at `~/.cua/start_mcp_server.sh`). Created `docs/services/cua-cursor-setup.md` with prerequisites, install steps, Cursor config, env vars, verification, and agent usage. Added pointers to Cua (and Qdrant) setup docs in README and wiki/Development-Tools.md.
- **Setup documented in:** [docs/services/cua-cursor-setup.md](docs/services/cua-cursor-setup.md)
- **Next 3 Specific Steps:** 1) Run the one-time install script if not already done. 2) Set `ANTHROPIC_API_KEY` in environment if required by Cua. 3) Restart Cursor and verify Cua tools in Composer.
- **Blockers/Concerns:** None.

### 2026-02-08 - Windows PC subdirectory
- **Date/Time:** 2026-02-08
- **Objective:** Create dedicated subdirectory for Windows PC (192.168.0.47) per dotfiles norms.
- **Actions Taken:** Created `scripts/windows-pc/` with README, TOC.md (full inventory), .env.example, ssh-windows.sh, run-inventory scripts, windows-system-inventory.ps1, inventory-rich.py. Created `docs/hardware/windows-pc-reference.md` with hardware summary. Updated ugoos/ssh-windows.sh to delegate to windows-pc. Added scripts/windows-pc/.env to gitignore.
- **Next 3 Specific Steps:** 1) Copy ugoos/.env to windows-pc/.env or rely on ugoos fallback. 2) Re-run inventory periodically to refresh TOC. 3) None.
- **Blockers/Concerns:** None.

### 2026-02-05 - Sonarr import fix (Sabnzbd remote path + permissions)
- **Date/Time:** 2026-02-05
- **Objective:** Fix local libraries empty—downloads stuck in queue, not importing.
- **Root cause:** (1) Sabnzbd in Docker reports `/downloads/`; Sonarr expects `/mnt/data/downloads/sabnzbd/`. (2) Files owned by pi:pi; Sonarr (sonarr user) couldn't read—UnauthorizedAccessException.
- **Actions Taken:** Added remote path mapping in Sonarr and Radarr (127.0.0.1: /downloads/ → /mnt/data/downloads/sabnzbd/). Fixed permissions (chown sonarr:media on completed downloads). Triggered DownloadedEpisodesScan—all 8 Inside Job S02 episodes imported to /mnt/data/media/tv/. Added sonarr/radarr to pi group for future downloads. Triggered Jellyfin library scan.
- **Next 3 Specific Steps:** 1) Verify Inside Job appears in Jellyfin TV library. 2) Add same remote path mapping to Lidarr if using Sabnzbd. LazyLibrarian has its own config. 3) None.
- **Blockers/Concerns:** None.

### 2026-02-05 - Zurg troubleshooting (successful setups)
- **Date/Time:** 2026-02-05
- **Objective:** Troubleshoot lingering Zurg/rclone issues using patterns from successful setups.
- **Actions Taken:** Created `docs/services/servarr-pi5-zurg-troubleshooting.md` from Unraid guide (hernandito), TheRandy Pi 5 success, rclone forum. Updated `jellyfin-mount-fix.sh` to stop rclone, run `fusermount -uz` for stale mounts, then start fresh. Added `zurg-rclone-host-mount.sh` for host-based rclone (maximum stability, like Unraid). Aligned setup script: cache volume, RCLONE_CACHE_DIR, 10s startup delay for rclone (per Unraid). Added VFS cache full warning to troubleshooting doc. Verified all servarr scripts with bash -n.
- **Next 3 Specific Steps:** 1) Run jellyfin-mount-fix.sh if libraries empty. 2) Try host rclone if Docker propagation remains flaky. 3) Remove duplicates in Real-Debrid web UI.
- **Blockers/Concerns:** None.

### 2026-02-05 - Zurg rclone playback fix
- **Date/Time:** 2026-02-05
- **Objective:** Fix "Playback failed due to a fatal player error" when trying to play Real-Debrid content.
- **Root cause:** rclone FUSE mount failed on file reads (Input/output error). FFmpeg couldn't read. Added `--vfs-read-ahead 512M`, `--buffer-size 256M`, `--vfs-cache-max-size 20G`, `--vfs-read-chunk-size 64M`.
- **Actions Taken:** Created `scripts/servarr/zurg-rclone-playback-fix.sh` for improved rclone mount. Ran fix; 1080p and most 4K files now read. "Cunk On Life" still fails—likely file-specific (expired on RD). Updated setup script and docs.
- **Next 3 Specific Steps:** 1) Try playing in Jellyfin again (e.g. 10 Cloverfield Lane 1080p). 2) Remove duplicates in Real-Debrid web UI. 3) Add JellySkin CSS if not done.
- **Blockers/Concerns:** None.

### 2026-02-03 - Session recovery: Jellyseerr Radarr/Sonarr configured
- **Date/Time:** 2026-02-03
- **Objective:** Recover session after connection loss; complete Jellyseerr Radarr/Sonarr setup.
- **Actions Taken:** Verified Jellyseerr container has `host.docker.internal` (ExtraHosts). Radarr and Sonarr were empty in settings.json. Created `scripts/servarr/jellyseerr-configure-radarr-sonarr.sh` and ran it: added Radarr (host.docker.internal:7878) and Sonarr (host.docker.internal:8989) with HD-1080p profile, correct root folders, API keys. Restarted Jellyseerr. Verified connectivity from container (401 = reachable).
- **Next 3 Specific Steps:** 1) Paste JellySkin CSS in Jellyfin if not done. 2) Add content to Real-Debrid and verify in Jellyfin. 3) Test a media request in Jellyseerr.
- **Blockers/Concerns:** None.

### 2026-02-03 - Jellyseerr fix (host.docker.internal)
- **Date/Time:** 2026-02-03
- **Objective:** Fix Jellyseerr unable to reach Radarr/Sonarr (localhost = container, not host).
- **Actions Taken:** Recreated Jellyseerr with `--add-host=host.docker.internal:host-gateway`. Updated setup script and docs to use `host.docker.internal` for Radarr/Sonarr. Created `scripts/servarr/jellyseerr-fix.sh` for quick re-apply.
- **Next 3 Specific Steps:** ~~1) In Jellyseerr UI, set Radarr/Sonarr~~ ✅ Done via script. 2) Paste JellySkin CSS in Jellyfin. 3) Add content to Real-Debrid and verify.
- **Blockers/Concerns:** None.

### 2026-02-03 - Servarr Pi5: Jellyseerr + Zurg + JellySkin
- **Date/Time:** 2026-02-03
- **Objective:** Deploy Jellyseerr, Zurg (Real-Debrid WebDAV), and JellySkin theme on Pi 5.
- **Actions Taken:** Jellyseerr deployed (port 5055). Zurg v0.9.3-hotfix.11 + rclone deployed (Pi lacks docker-compose; used docker run). Jellyfin recreated with /mnt/zurg mount. Real-Debrid Movies and Real-Debrid TV libraries added via API (query params). JellySkin documented for manual paste in Dashboard → General → Custom CSS.
- **Next 3 Specific Steps:** 1) Configure Jellyseerr with Jellyfin + Radarr + Sonarr in UI. 2) Paste JellySkin CSS in Jellyfin. 3) Add content to Real-Debrid and verify it appears in Jellyfin.
- **Blockers/Concerns:** None.

### 2026-02-03 - NPM Routing Verification
- **Date/Time**: 2026-02-03
- **Objective**: Test hostnames via browser and verify NPM routing.
- **Key Findings**: All six hostnames (rules, sso, nas, immich, n8n, syncthing) redirect to TrueNAS `/ui/` because TrueNAS occupies port 80/443; NPM proxy hosts never receive traffic.
- **Actions Taken**: curl tests with Host headers; browser verification of port 80 and 30081; created `docs/truenas/npm-routing-test-results.md`.
- **Next 3 Specific Steps**:
  1. Change TrueNAS web ports (80→81, 443→444) so NPM can bind to 80/443.
  2. Ensure NPM container has host ports 80 and 443 mapped.
  3. Re-test hostnames after port change.
- **Blockers/Concerns**: None.

### 2026-02-02 - TrueNAS Rules Hosting Plan
- **Date/Time**: 2026-02-02 13:50 CST
- **Objective**: Stand up TrueNAS-hosted static rules site for Cursor indexing and proxy it via NPM.
- **Key Decisions**:
  - Decision: Host rules docs on TrueNAS via a Custom App static web container behind NPM.
    Rationale: Keeps hosting local and aligns with existing NPM reverse proxy.
    Alternatives: Cloudflare Pages, other public hosting.
    Impact: Requires dataset path, custom app configuration, and NPM proxy setup.
    Date: 2026-02-02
- **Actions Taken**: Reviewed TrueNAS 25.04 Apps and Custom App docs for storage and port mapping guidance. Created NPM Proxy Host `rules.xcvr.link` → `192.168.0.158:30081`. Created custom app `rules-static` (nginx:alpine) with host port `30081` and host path `/mnt/tank/apps/rules_server` mounted to `/usr/share/nginx/html` (read-only). Verified `http://192.168.0.158:30081` returns 403 (no files yet).
- **Next 3 Specific Steps**:
  1. Add `index.html`, `robots.txt`, `sitemap.xml` to `/mnt/tank/apps/rules_server`.
  2. Verify `rules.xcvr.link` serves the static site through NPM.
  3. Add `rules.xcvr.link` to Cursor Indexing & Docs and confirm crawl.
- **Blockers/Concerns**: None.

### 2026-01-31 - Cursor Docs Indexing Research
- **Date/Time**: 2026-01-31
- **Objective**: Determine best format and hosting approach for Cursor docs indexing for rules site.
- **Key Decisions**: Recommend a static HTML docs site with stable URLs and crawlable subpages; include sitemap/robots that allow crawling.
- **Actions Taken**: Reviewed Cursor @Docs documentation and confirmed URL-based crawling of subpages; inspected Cursor crawler `docs.jsonl` to see `crawlerStart` + `crawlerPrefix` patterns.
- **Next 3 Specific Steps**:
  1. Choose hosting approach for `rules.xcvr.link` (TrueNAS + NPM vs Cloudflare Pages).
  2. Build static docs output (mkdocs or docusaurus) with clean HTML and sitemap.
  3. Add `rules.xcvr.link` in Cursor **Indexing & Docs** and verify indexing.
- **Blockers/Concerns**: None.

### 2026-02-02 - Servarr Pi 5 Phase 4 (Jellyfin)
- **Date/Time**: 2026-02-02
- **Objective**: Complete Phase 4 Jellyfin setup (libraries, hardware acceleration).
- **Key Decisions**: (1) Pi 5 lacks hardware encoders; Jellyfin deprecated V4L2 for Raspberry Pi—documented, no HW accel config. (2) Setup wizard requires manual completion (browser automation couldn't get element refs). (3) Library add automated via script after wizard.
- **Actions Taken**: Created `scripts/servarr-pi5-phase4-jellyfin-config.sh` (auth + add Movies, TV, Music, Books libraries). Updated `servarr-pi5-post-install-status.md` and `servarr-pi5-setup-plan.md` with Pi 5 HW accel note.
- **Next 3 Specific Steps**:
  1. Complete Jellyfin wizard at http://pi5.xcvr.link:8096 (create admin user)
  2. Run `JF_PASS=xxx ./scripts/servarr-pi5-phase4-jellyfin-config.sh` to add libraries
  3. Add Prowlarr indexers, sync to *arr apps
- **Blockers/Concerns**: None.

### 2026-01-31 - Dotfiles Maintenance Research
- **Date/Time**: 2026-01-31
- **Objective**: Research dotfiles maintenance, backup strategy, incremental updates; clarify 200-line rule vs Qdrant.
- **Key Decisions**: (1) Qdrant chunks before embedding—original file size irrelevant; 200-line rule serves human/agent context, not vector search. Keep rule for docs; relax for Qdrant-only or machine-only files. (2) Link script already backs up conflicts to `~/.dotfiles_backup_*`; add git tag for restore points. (3) Bootstrap references non-existent `bin/link`; fix to use `scripts/system/link`.
- **Actions Taken**: Created `docs/dotfiles_maintenance_guide.md` with backup strategy, one-by-one update process, verification targets, rules rework notes, maintenance order. Added to docs/README.md.
- **Next 3 Specific Steps**:
  1. Fix `scripts/system/bootstrap` (path + REPO_ROOT)
  2. Update shell config (`.zshrc`, starship) and verify
  3. Align README/wiki with actual script paths (`scripts/system/link` vs `bin/link`)
- **Blockers/Concerns**: None.

### 2026-01-30 - Car Thing CLI Push + Hot Reload
- **Date/Time**: 2026-01-30
- **Objective**: Reverse-engineer DeskThing to enable CLI push and hot reload for Car Thing app.
- **Key Decisions**: DeskThing apps are served by the server (not pushed via ADB); base client is pushed to `/usr/share/qt-superbird-app/webapp`. Hot reload uses LiteClient + Dev Mode + `adb reverse` to forward Vite port. CLI push copies built app to `~/Library/Application Support/deskthing/apps/<id>/`.
- **Actions Taken**: Cloned DeskThing source; traced `adbService.pushWebApp`, `configureDevice`, `pushClient`; found Dev Mode in DevAppPage (adb reverse for dev port). Created `car-thing/scripts/push.sh` (build + --install copies to DeskThing apps, --open opens dist); `car-thing/scripts/dev-hot-reload.sh` (adb reverse 5173). Updated docs with CLI push and hot reload flow.
- **Next 3 Specific Steps**:
  1. Install LiteClient on Car Thing for hot reload
  2. Test hot reload flow end-to-end
  3. Add macro/launcher endpoints (Hammerspoon HTTP server)
- **Blockers/Concerns**: None.

### 2026-01-20 - Syncthing Setup (Replace Seafile)
- **Date/Time**: 2026-01-20 22:06:40 CST
- **Objective**: Replace Seafile with Syncthing for simple file sync + ZFS snapshots.
- **Key Decisions**: Decision: Use Syncthing instead of Seafile. Rationale: Seafile too complex/troublesome; Syncthing lightweight, simple, works on current hardware. Alternatives: Nextcloud (needs RAM upgrade), keep trying Seafile. Impact: Simpler setup, real files for Qdrant indexing, no database complexity. Date: 2026-01-20
- **Actions Taken**: Created Syncthing setup guide; documented Seafile removal steps.
- **Next 3 Specific Steps**:
  1. Stop and remove Seafile app from TrueNAS
  2. Install Syncthing via TrueCharts catalog or custom app
  3. Configure folders and connect devices
- **Blockers/Concerns**: None - Syncthing works on current 8GB RAM.

### 2026-01-20 - DXP2800 RAM Upgrade Research
- **Date/Time**: 2026-01-20 22:05:21 CST
- **Objective**: Identify best compatible RAM upgrade for UGREEN DXP2800.
- **Key Decisions**: Use vendor/spec sources to confirm max capacity and DDR5 SODIMM requirements before recommending a module.
- **Actions Taken**: Confirmed DXP2800 uses DDR5-4800 SODIMM and official max 16GB; selected a specific 16GB module.
- **Next 3 Specific Steps**:
  1. Share final RAM recommendation with part number and links
  2. Provide install notes and verification steps
  3. Confirm post-upgrade memory recognition
- **Blockers/Concerns**: None.

### 2026-01-20 - Nextcloud Burden Assessment (NAS)
- **Date/Time**: 2026-01-20 21:55:57 CST
- **Objective**: Estimate Nextcloud resource burden for current NAS by collecting CPU/RAM/storage info via SSH.
- **Key Decisions**: Use SSH (non-interactive) to gather minimal system stats before recommending Nextcloud vs Syncthing.
- **Actions Taken**: Ran SSH probes; confirmed Intel N100 (4C) and ~7.5 GiB RAM with ~1.1 GiB available; noted tight headroom for heavier apps.
- **Next 3 Specific Steps**:
  1. Estimate Nextcloud baseline/peak on 8 GiB RAM and N100
  2. Provide recommendation and fallback (Syncthing + ZFS snapshots)
  3. Outline Qdrant integration path for chosen storage
- **Blockers/Concerns**: Low free RAM (~1.1 GiB) suggests Nextcloud may cause contention during scans/previews.

### 2026-01-20 - Cloudflare Domain Access for Home Services
- **Date/Time**: 2026-01-20 21:46 CST
- **Objective**: Enable `*.xcvr.link` access to internal services from inside and outside the network.
- **Key Decisions**:
  - Decision: Use split-horizon DNS with a local resolver plus a reverse proxy for `*.xcvr.link`.
  - Rationale: Single hostname works internally/externally; internal traffic stays local; proxy handles TLS.
  - Alternatives: Separate internal domain, hosts-file overrides, relying on NAT hairpin only, Cloudflare Tunnel-only.
  - Impact: Requires internal DNS records, reverse proxy config, TLS certificate strategy.
  - Date: 2026-01-20
  - Decision: Use Cloudflare Tunnel for external access (Option B).
  - Rationale: Avoids installing Tailscale on all devices and avoids opening inbound ports.
  - Alternatives: Tailscale-only access, port-forwarding 80/443.
  - Impact: Requires `cloudflared` running on LAN and Cloudflare Zero Trust setup.
  - Date: 2026-01-20
  - Decision: Move historical session records to `docs/session_records_index.md`.
  - Rationale: Keep `project_context.md` under 200 lines and maintain a single index.
  - Alternatives: Keep all records in `project_context.md`; split without an index.
  - Impact: Session history lives in docs; project_context holds current session.
  - Date: 2026-01-20
- **Actions Taken**: Created `docs/rules/file_size_management_rule.md`; split session records into docs; added session records index; replaced `session_records.md` with pointer; updated pre-action checklist; prepared DNS/proxy guidance; captured requirement for college-level explanation; noted Cloudflare Tunnel preference and questions about resource impact and cost.
- **Next 3 Specific Steps**:
  1. Confirm local DNS solution on UDM Pro or decide on Pi-hole/AdGuard
  2. Decide where to run reverse proxy + `cloudflared` (NAS app or other host)
  3. Configure Cloudflare Tunnel + proxy and verify inside/outside resolution
- **Blockers/Concerns**: Limited free RAM on NAS; need to validate headroom for proxy + tunnel

Historical session records live in `docs/session_records_index.md`.

### 2026-02-02 - Car Thing Phase 6 (Feed)
- **Date/Time**: 2026-02-02
- **car_thing_current_phase**: 6
- **Status**: Complete
- **Actions Taken**: Implemented Phase 6 Feed. Renamed Notifications → Feed. Bridge: GET /feed fetches RSS from config/feed.json, parses items. Server: get-feed handler. FeedTab: displays items with title, summary, link. Config: feed.example.json.
- **Next**: Phase 5 (miniDSP) if hardware present; Phase 7 (more feed sources).

### 2026-01-30 - Car Thing Phase 4 (Output Device Switch)
- **Date/Time**: 2026-01-30
- **car_thing_current_phase**: 4
- **Status**: Complete
- **Actions Taken**: Implemented Phase 4 (Output Device Switch) and mic-mute state sync. Bridge: GET /audio/devices, GET /audio/mic-muted, POST /control output-device. Server: get-audio-devices, get-mic-muted handlers. ControlTab: device selector, mic state sync on mount.
- **Next**: Phase 6 (Feed) — done.

## Next Steps
1. Decide where to run reverse proxy + `cloudflared` for `immich.xcvr.link`
2. Configure Cloudflare Tunnel and reverse proxy routing
3. Add local DNS record and verify internal/external access

## Notes
- Repository follows lowercase naming convention with underscores
- All configuration files are symlinked from dotfiles to appropriate system locations
- Backup system preserves existing configurations before linking
- Files are kept under 200 lines with automatic splitting when exceeded

## Documentation Organization (2026-01-24)
- **Archived**: Seafile docs (replaced with Syncthing), Caddy docs (removed), old Qdrant/Ugreen troubleshooting files
- **Organized**: Documentation grouped by topic (truenas/, services/, hardware/, networking/, migration/, macos/)
- **Structure**: Active docs in root, archived in `docs/archive/`, organized by category in subdirectories
- **See**: `docs/README.md` for full organization structure