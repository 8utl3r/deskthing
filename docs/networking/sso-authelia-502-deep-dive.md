# SSO / Authelia 502 — Deep Dive

**Symptom:** `sso.xcvr.link` returns **502 Bad Gateway** when requested through NPM+ (port 80). Authelia responds **200** when hit directly from the Mac at `http://192.168.0.158:30133`.

**Root cause:** The NPM+ container cannot reach Authelia. NPM+ runs as a TrueNAS Docker app; Authelia runs as another TrueNAS app. Each app typically gets its own network namespace, so the NPM+ container cannot reliably reach `192.168.0.158`, `host.docker.internal`, or `authelia` (hostname).

---

## 1. What We Know

| Component | Status |
|-----------|--------|
| Authelia | Running on host port **30133** |
| Direct from Mac | `curl http://192.168.0.158:30133/` → **200** |
| NPM+ proxy | `sso.xcvr.link` → forward to `192.168.0.158:30133` |
| Through NPM+ | `curl -H "Host: sso.xcvr.link" http://192.168.0.158:80/` → **502** |
| NPM+ container | Runs on TrueNAS; tries to connect to backend from inside its network |

**Conclusion:** The request reaches NPM+ (port 80). NPM+ then tries to proxy to the backend. The backend connection fails → 502.

---

## 2. Why the Backend Connection Fails

### Network isolation

TrueNAS Scale 24.10+ runs apps as Docker containers. By default:

- Each app gets its own network (bridge or similar).
- A container sees itself and its network; it does **not** automatically see the host’s LAN IP or other apps’ hostnames.
- `192.168.0.158` from inside the NPM+ container may be:
  - Unreachable (no route from container bridge to host),
  - Or may resolve to something else (e.g. another container or interface).

### What we tried

| Forward host | Result | Reason |
|--------------|--------|--------|
| `192.168.0.158` | 502 | Container likely cannot route to host LAN IP from its bridge network |
| `host.docker.internal` | 502 | Not injected by TrueNAS Docker; hostname does not resolve |
| `authelia` | 502 | NPM+ and Authelia are on different app networks; no shared DNS |

### Why it worked with the old NPM

From `truenas-app-service-urls.md`:

> NPM uses `authelia:30133` — works from NPM's container. Container names tested from host: `authelia` does NOT resolve (host DNS). NPM uses `authelia` successfully, so it resolves from within the container network.

The **old NPM** (jc21) and Authelia were on the **same container network** (e.g. shared k3s/Docker network), so `authelia` resolved and was reachable. After migrating to **NPM+** as a new TrueNAS app, NPM+ and Authelia are likely on **different networks**, so `authelia` no longer resolves and 192.168.0.158 is not routable from the container.

---

## 3. Architecture Snapshot

```
                    LAN (192.168.0.x)
                            │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
    │  Mac                  │  TrueNAS host         │
    │  curl → 192.168.0.158 │  192.168.0.158        │
    │                       │  :80 (NPM+)           │
    │                       │  :30133 (Authelia)    │
    │                       │  :81 (TrueNAS UI)     │
    │                       │  ...                  │
    │                       │                       │
    │                       │  ┌─────────────────┐  │
    │                       │  │ NPM+ container  │  │
    │                       │  │ bridge network  │  │
    │                       │  │ tries to reach  │  │
    │                       │  │ 192.168.0.158  │──┼──→ fails (no route)
    │                       │  │ or authelia    │  │
    │                       │  └─────────────────┘  │
    │                       │                       │
    │                       │  ┌─────────────────┐  │
    │                       │  │ Authelia        │  │
    │                       │  │ different       │  │
    │                       │  │ network         │  │
    │                       │  └─────────────────┘  │
    └───────────────────────┼───────────────────────┘
                            │
```

---

## 4. Fix Options (in order of preference)

### Option A: Host network for NPM+

If NPM+ can use **host network mode**, it shares the host’s network stack and can reach `127.0.0.1:30133` or `192.168.0.158:30133`.

**Steps:**

1. In TrueNAS: **Apps** → **Installed** → **npmplus** → **Edit**
2. Look for **Network** or **Advanced** settings
3. Enable **Host network** (or equivalent) if available
4. Save; app may restart
5. Change sso proxy to `127.0.0.1:30133` or keep `192.168.0.158:30133`
6. Run verification: `./scripts/npm/verify-proxy-hosts.sh`

**Caveat:** Host network may not be exposed in all TrueNAS app charts. If the option is missing, try Option B or C.

---

### Option B: Cloudflare Tunnel direct to Authelia (bypass NPM for SSO)

Route `sso.xcvr.link` directly to Authelia instead of through NPM+.

**Steps:**

1. Cloudflare Zero Trust → **Networks** → **Tunnels** → [Your tunnel] → **Public Hostnames**
2. Edit the `sso` / `xcvr.link` route
3. Change service URL from `http://192.168.0.158:80` to `http://192.168.0.158:30133`
4. Save

**Effect:** `https://sso.xcvr.link` → Cloudflare Tunnel → Authelia directly. No NPM+ in the path. SSO works; other hostnames still go through NPM+.

---

### Option C: Put NPM+ and Authelia on the same network

If TrueNAS supports **custom/external networks** or **network sharing** for apps:

1. Create a shared network (or use an existing one)
2. Attach both NPM+ and Authelia to that network
3. Use hostname `authelia:30133` in the sso proxy host
4. Run: `NPM_URL=https://192.168.0.158:30360 ./scripts/npm/npm-api.sh fix-sso` to revert to `192.168.0.158`, then edit in NPM+ UI to `authelia:30133`

**Caveat:** Depends on TrueNAS 24.10 Docker app networking; not all charts expose this.

---

### Option D: Run Authelia on the same host as NPM+ via host network

If Authelia can use host network, it would listen on the host’s `0.0.0.0:30133`. From NPM+’s perspective the situation is unchanged unless NPM+ also uses host network.

---

## 5. Diagnostic Commands

Run these to confirm network topology and narrow down the issue.

### From your Mac (verify Authelia and NPM+ proxy)

```bash
# Authelia direct
curl -s -o /dev/null -w "%{http_code}" http://192.168.0.158:30133/
# Expect: 200

# sso through NPM+
curl -s -o /dev/null -w "%{http_code}" -H "Host: sso.xcvr.link" http://192.168.0.158:80/
# Current: 502
```

### From TrueNAS (SSH, see what NPM+ container can reach)

```bash
# Source env for sudo password
source /Users/pete/dotfiles/factorio/.env.nas

# Find NPM+ container (TrueNAS 24.10 Docker)
ssh truenas_admin@192.168.0.158 "echo '$NAS_SUDO_PASSWORD' | sudo -S docker ps --format '{{.Names}}' | grep -i npm"
# Or: ssh ... "sudo -S crictl ps"  if using containerd

# Exec into NPM+ container and test connectivity (replace CONTAINER with actual name)
ssh truenas_admin@192.168.0.158 "echo '$NAS_SUDO_PASSWORD' | sudo -S docker exec CONTAINER sh -c 'curl -s -o /dev/null -w \"%{http_code}\" --connect-timeout 2 http://192.168.0.158:30133/ || echo failed'"

# Test if authelia resolves
ssh truenas_admin@192.168.0.158 "echo '$NAS_SUDO_PASSWORD' | sudo -S docker exec CONTAINER getent hosts authelia || echo 'authelia: no resolution'"

# Test host.docker.internal
ssh truenas_admin@192.168.0.158 "echo '$NAS_SUDO_PASSWORD' | sudo -S docker exec CONTAINER getent hosts host.docker.internal || echo 'host.docker.internal: no resolution'"
```

(If `docker ps` returns nothing, TrueNAS may use a different runtime; check the Apps UI for workload/container details.)

---

## 6. Recommended Path

1. **Try Option B first** (tunnel direct to Authelia): No change to NPM+; quickest fix.
2. **If you want sso through NPM** (e.g. for SSL/snippets): Try **Option A** (host network for NPM+).
3. **If both fail:** Consider **Option C** (shared network) if your TrueNAS version and app charts support it.

---

## 7. Related Docs

- `truenas-app-service-urls.md` — Host ports, why `authelia` worked from old NPM
- `sso-completion-investigation.md` — SSO setup checklist
- `npmplus-dns-tunnel-diagram-and-verification.md` — Diagram, verification, fixes table
