# Headscale / Tailscale Health & State Report

**Checked:** 2026-02-09 (this Mac + router)

## Summary

| Component | Status | Notes |
|-----------|--------|--------|
| **This Mac (Tailscale)** | ✅ Healthy | Connected to Headscale; RouteAll, CorpDNS, MagicDNS on |
| **Router (UDM Pro)** | ✅ Healthy | Active, direct path 192.168.0.1:41641 |
| **Headscale server (TrueNAS 192.168.0.158)** | ✅ Reachable | HTTP port 30210 open; Tailscale clients use it |
| **Headscale CLI (remote)** | ✅ Via SSH | Use `scripts/truenas/headscale-remote.sh nodes list` (uses SSH + keychain sudo); gRPC 50443 not needed |

---

## This computer (Mac)

- **Tailscale:** Running, logged in to Headscale at `http://192.168.0.158:30210`.
- **Tailscale IPs:** `100.64.0.1` (IPv4), `fd7a:115c:a1e0::1` (IPv6).
- **Preferences:** RouteAll=true, CorpDNS=true, MagicDNS=xcvr.link, no exit node.
- **DNS name:** `invalid-qfcnzrqp.xcvr.link` — the `invalid-` prefix usually means the hostname sent to Headscale was rejected (e.g. spaces in "MacBook Pro"). Cosmetic only; connectivity is fine.
- **Connectivity:** Direct ping to router over Tailscale (`100.64.0.2`) works (~1 ms). LAN (192.168.0.x) reachable as normal.

---

## Router (UDM Pro)

- **Tailscale:** Active; shows as `router` / `router.xcvr.link`.
- **Tailscale IP:** `100.64.0.2`.
- **Path:** Direct to this Mac at `192.168.0.1:41641` (router’s LAN IP).
- **Role:** Subnet router (advertises LAN to Headscale). Route approval must be done on the Headscale server; remote CLI cannot be used until gRPC is available.

---

## Headscale (TrueNAS 192.168.0.158)

- **Reachability:** Ping and Tailscale control (HTTP) work. Port **30210** (HTTP) is open; port **50443** (gRPC) is **closed** (connection refused).
- **Impact:** The `headscale` CLI (from this Mac) uses gRPC and fails with “Could not connect: context deadline exceeded” because it targets 50443. Use `scripts/truenas/headscale-remote.sh` (SSH + keychain sudo) to run headscale from this Mac instead.

---

## Recommendations

1. **Fix Mac hostname in Headscale (optional):** To get a cleaner DNS name than `invalid-qfcnzrqp.xcvr.link`, set a single-word hostname before re-registering or rename the node in Headscale (e.g. `macbook` or `mbp`). Use `headscale-remote.sh` or SSH to TrueNAS to run headscale commands.
2. **Subnet routes:** Router’s advertised route 192.168.0.0/24 is present and enabled in Headscale; other tailnet devices can reach your LAN.

---

## Commands used for this check

```bash
tailscale status
tailscale status --json
tailscale netcheck
tailscale debug prefs
tailscale ping -c 2 100.64.0.2
# Headscale via SSH (no gRPC needed)
./scripts/truenas/headscale-remote.sh nodes list
./scripts/truenas/headscale-remote.sh nodes list-routes
nc -z -v -w 2 192.168.0.158 30210   # OK
nc -z -v -w 2 192.168.0.158 50443  # Connection refused
```
