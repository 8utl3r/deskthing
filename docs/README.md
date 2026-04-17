# Documentation Organization

## Structure

### Active Documentation (Root)
- `session_records_*.md` - Historical session records (indexed in `session_records_index.md`)
- `session_records_index.md` - Index of all session records
- `dotfiles_maintenance_guide.md` - Incremental updates, backups, rules analysis
- `DESKTOP_MANAGEMENT_GUIDE.md` - Desktop management guide
- `dotfiles_unknowns.md` - Unresolved questions/unknowns
- `inbox.md` - Active inbox for tangents and future tasks

### Organized by Topic

#### `truenas/` - TrueNAS Scale Guides
Installation, configuration, and troubleshooting guides for TrueNAS Scale on the NAS. Includes `truenas-apps-sso-and-updates.md` (running Authelia/PocketID via web UI; catalogs vs YAML; update notifications) and `sso-setup-walkthrough.md` (step-by-step NPM + Authelia SSO, including Install via YAML if Authelia isn’t in catalog).

#### `services/` - Service Documentation
Documentation for services running on TrueNAS and other hosts:
- Servarr + Jellyfin on Raspberry Pi 5 (`servarr-pi5-setup-plan.md`, `servarr-pi5-architecture.md`, `servarr-pi5-zurg-troubleshooting.md`)
- Audible & Kindle equivalents: `services/servarr-audiobooks-ebooks-setup.md` — setup walkthrough: `services/servarr-lazylibrarian-setup-walkthrough.md`
- SSO for exposed subdomains: feature matrix (`sso-feature-matrix.md`), glossary (`sso-glossary.md`), explained features (`sso-features-explained.md`) — Authelia, Authentik, Keycloak, PocketID, oauth2-proxy, Vouch, Tailscale
- Qdrant (vector database)
- n8n (workflow automation)
- Copyparty (file sharing)
- Wikipedia indexing
- Vector mapper setup

#### `hardware/` - Hardware Guides
Hardware-specific documentation:
- Car Thing (Spotify → DeskThing): setup, custom app development
- Ugreen DXP2800 NAS setup and configuration
- Rabbit R1 modding guides
- Ugoos SK1 TV box reference (`ugoos-sk1-reference.md`)
- Windows PC reference (`windows-pc-reference.md`) — 192.168.0.47, SK1 flashing host
- LG C5 monitor (in `lg-c5/` subdirectory)

#### `networking/` - Network Configuration
Network and infrastructure documentation:
- **`NETWORK_REFERENCE.md`** — Complete network reference (IPs, DNS, Cloudflare, credentials, verification). Start here for agent handoff.
- Cloudflare Tunnel setup
- DNS configuration
- Reverse proxy guides
- UniFi configuration
- Headscale CLI setup (`headscale-cli-setup.md`) — remote control of Headscale on TrueNAS
- UDM Pro as Headscale subnet router (`udm-pro-headscale-subnet-router-guide.md`)
- Headscale + Mullvad exit node (`headscale-mullvad-exit-node.md`) — proxy tailnet internet traffic via Mullvad

#### `migration/` - Migration Guides
Migration documentation for moving from Google services to self-hosted alternatives.

#### `macos/` - macOS-Specific
macOS system configuration and troubleshooting:
- Homebrew update analysis
- macOS Sequoia fixes
- Audio optimization

#### `home-assistant/` - Home Assistant
Home Assistant integration and automation documentation.

#### `rules/` - Project Rules
Project management rules and compliance documentation.

### Archive

#### `archive/` - Historical/Deprecated Files
Archived files organized by topic:
- `seafile/` - Seafile documentation (replaced with Syncthing)
- `caddy/` - Caddy reverse proxy docs (removed in favor of Cloudflare Tunnel)
- `qdrant/` - Old Qdrant configuration variants
- `ugreen/` - Ugreen troubleshooting files (installation complete)
- `old-configs/` - Deprecated configuration files

## Notes

- Files are organized by topic for easy navigation
- Archive contains historical files that may be referenced but are no longer active
- Session records remain in root for easy access via index
