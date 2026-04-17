# Nginx Proxy Manager vs NPMplus (Plus) — Feature Matrix

**Context:** The original **Nginx Proxy Manager (NPM)** is from jc21/NginxProxyManager. **NPMplus** (often labeled “Nginx Proxy Manager Plus” in catalogs) is a community fork at [ZoeyVid/NPMplus](https://github.com/ZoeyVid/NPMplus) that adds security and performance features. Both are free and open source.

---

## Feature comparison

| Feature | Nginx Proxy Manager | NPMplus (Plus) |
|--------|----------------------|----------------|
| **Web GUI** | Yes | Yes (same base) |
| **Proxy hosts** | Yes | Yes |
| **Let's Encrypt / ACME** | Yes | Yes |
| **No manual nginx config** | Yes | Yes |
| **Docker deploy** | Yes | Yes |
| **Default database** | SQLite (no separate DB container) | SQLite (no separate DB container) |
| **HTTP/3 & QUIC** | No | Yes (native support; 443/UDP) |
| **CrowdSec integration** | No | Yes (WAF / intrusion protection, log parsing) |
| **Geo-blocking** | No | Optional (via nginx module + env; not a built-in UI feature) |
| **Performance / stability** | Standard | Tuned (memory, startup, many hosts) |
| **Dark mode** | No (or optional) | Yes (default) |
| **Project activity** | Mature, less frequent commits | Actively developed fork |
| **Migration from NPM** | — | Supported (mount existing `/etc/letsencrypt` once; certs moved to `/data`) |

---

## When to use which

**Stick with Nginx Proxy Manager if:**
- You want the best-documented, “default” choice.
- You’re only proxying a few internal or low-exposure services.
- You don’t need HTTP/3 or CrowdSec.

**Prefer NPMplus (Plus) if:**
- You expose services to the internet and want CrowdSec-based protection.
- You want HTTP/3/QUIC for better performance (especially on mobile/unreliable networks).
- You want a single container, dark UI, and more active development on top of NPM.

---

## Notes (from NPMplus author)

- NPM and NPMplus both use **SQLite by default**; neither requires a separate MySQL container.
- **Geo-blocking** in NPMplus is via an optional nginx module (env-configurable), not a full built-in UI.
- **Migration:** Use the `/etc/letsencrypt` mount only for the initial migration; NPMplus then stores certs under `/data` and the mount can be removed.

---

## TrueNAS Apps

If the TrueNAS catalog lists **“Nginx Proxy Manager”** and **“Nginx Proxy Manager Plus”**, the Plus option is likely the NPMplus image (e.g. `zoeyvid/npmplus`). Check the app’s image source in the install screen to confirm.

**References:**  
[Virtualization Howto: NPM vs NPMplus](https://www.virtualizationhowto.com/2025/09/nginx-proxy-manager-vs-npmplus-which-one-is-better-for-your-home-lab/), [CrowdSec NPMplus quickstart](https://docs.crowdsec.net/docs/next/appsec/quickstart/npmplus), [ZoeyVid/NPMplus](https://github.com/ZoeyVid/NPMplus)
