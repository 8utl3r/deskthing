# Connect Your Phone to Headscale

Your Headscale server has one **user**: **pete**. All devices (Mac, UDM Pro router, phone) join under that user.

## Current state (from your server)

- **Users:** pete (id 1)
- **Nodes:** Mac (online), router / UDM Pro (offline when checked)

## Add your phone

### 1. Get a login URL or auth key

**Option A – Pre-auth key (no tap in app)**  
From your Mac:

```bash
./scripts/truenas/headscale-remote.sh preauthkeys create -u 1 --reusable --expiration 720h
```

Copy the line that looks like `hskey-auth-...` or `preauthkey:...`. Use it in the Tailscale app as the auth key when adding the custom server.

**Option B – Login URL (tap to approve)**  
Use the custom server URL (step 2). When you “Sign in”, the app will open a browser or show a URL; open it on a device that can reach Headscale and complete login. No pre-auth key needed.

### 2. Headscale server URL

- **HTTPS (recommended):** **`https://headscale.xcvr.link`** — Add `headscale` to your Cloudflare Tunnel so the Tailscale app gets a valid certificate. Same tunnel route as other hosts: headscale / xcvr.link → http://192.168.0.158:80. NPM already proxies to 30210.
- **HTTP on LAN only:** `http://headscale.xcvr.link` (many Tailscale builds deny HTTP; use HTTPS above).
- **By IP (fallback):** `http://192.168.0.158:30210`

Your phone must be able to reach this URL (on LAN or via tunnel).

**If you get `tls: unrecognized name`:** The TLS server (NPM when the phone hits your LAN) has no certificate for `headscale.xcvr.link`. Fix: add an SSL certificate in NPM for that host (see **Fix HTTPS / “unrecognized name”** below).

### 3. Android

1. Install **Tailscale** from [Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn) or [F-Droid](https://f-droid.org/packages/com.tailscale.ipn/) (1.30.0+ for custom server).
2. Open the **settings** menu (gear or three lines in the **top-right**).
3. Tap **Accounts**.
4. Tap the **kebab menu** (⋮ **three dots**) in the **top-right** of that screen.
5. Choose **Use an alternate server** (or “Change server” on some versions).
6. Enter your Headscale URL: **`https://headscale.xcvr.link`** (no port). Save if prompted; the app may restart.
7. **Sign in:**
   - **With auth key:** From the ⋮ menu choose **Use an auth key**, paste the key from step 1, then tap **Log in** on the main screen.
   - **Without key:** Tap **Log in** and complete the in-app browser flow to approve the device on Headscale.

### 4. iPhone

1. Install **Tailscale** from the App Store.
2. Tap the **account icon** (top-right) → **Log in…** → tap the **⋮ options** menu (top-right) → **Use custom coordination server**.
3. Enter the Headscale URL: **`https://headscale.xcvr.link`**.
4. Sign in with an auth key or follow the in-app login. (On some iOS versions this flow is buggy; TestFlight builds or using the auth-key method can help.)

## After connecting

- The phone will appear under user **pete** in Headscale (`./scripts/truenas/headscale-remote.sh nodes list`).
- If you use **Tailscale DNS** and set Headscale to use the router (192.168.0.1), the phone will resolve `*.xcvr.link` via your router when on Tailscale.
- From the phone you can reach home hosts (e.g. nas.xcvr.link, immich.xcvr.link) via the UDM Pro subnet router when it’s online and routes are approved.

## Fix HTTPS / “unrecognized name”

Error: `fetch control key: GET "https://headscale.xcvr.link/key?v=...": remote error: tls: unrecognized name`

**Cause:** On the phone, `headscale.xcvr.link` resolves to your NAS (Local DNS). The connection goes to NPM on port 443, but the Headscale proxy host in NPM has **no SSL certificate** for that name, so TLS fails.

**Fix (in NPM):**

1. **Tunnel first**  
   In **Cloudflare Dashboard → Zero Trust → Tunnels** → your tunnel → **Public Hostnames**, add:  
   **headscale** / **xcvr.link** → **http://192.168.0.158:80**

2. **Request a certificate in NPM**  
   - **NPM+** (https://192.168.0.158:30020 or :30360) → **Hosts** → **Proxy Hosts** → **headscale.xcvr.link** → **Edit**  
   - Open the **SSL** tab  
   - Under **SSL Certificate**, choose **Request a new SSL Certificate**  
   - Domain: **headscale.xcvr.link** (and optionally **www.headscale.xcvr.link** if you use it)  
   - Use **Let's Encrypt**; HTTP-01 is enough (validation will go: Let's Encrypt → Cloudflare → tunnel → NPM)  
   - Save. Wait for the cert to be issued.

3. **Use the cert on the proxy host**  
   - In the same **Edit** screen, **SSL** tab  
   - **SSL Certificate:** select the certificate you just created  
   - Turn on **Force SSL** if you want  
   - Save

After that, both “phone on LAN → NPM” and “phone via Cloudflare” will see a valid cert for `headscale.xcvr.link` and the Tailscale app should connect.

## Generate a new pre-auth key (one-liner)

```bash
./scripts/truenas/headscale-remote.sh preauthkeys create -u 1 --reusable --expiration 720h
```

(`-u 1` = user id 1 = pete; 720h = 30 days. Omit `--reusable` for one-time use.)
