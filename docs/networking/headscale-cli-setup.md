# Headscale CLI Setup (Remote Control from Mac)

Use the `headscale` CLI on your Mac to control Headscale running on TrueNAS. The CLI connects over gRPC and requires an API key.

## 1. Install the CLI

```bash
brew install headscale-cli
```

Or run `brew bundle` from your dotfiles to install everything in the Brewfile.

## 2. Expose gRPC Port on TrueNAS (If Needed)

The Headscale CLI uses **gRPC** on port **50443**. The TrueNAS Headscale app may only expose the HTTP API port (e.g. 30210) by default.

- **Check:** In TrueNAS → Apps → headscale → Edit → Network, see which ports are published.
- **If 50443 is not exposed:** Add a port mapping for **50443** (container port 50443 → host 50443), or check the app's chart for a gRPC port option.
- **If the app uses a different gRPC port:** Update `HEADSCALE_CLI_ADDRESS` in your `.env` to use that port.

## 3. Create an API Key (One-Time)

You need an API key to authenticate the remote CLI. The key must be created **on the Headscale server** (TrueNAS container).

### Option A: TrueNAS "Execute Command" or "Run"

If the Headscale app has an "Execute Command" / "Run" / "Console" feature where you can run a **specific command** (not open a shell), use it:

```bash
headscale apikeys create --expiration 90d
```

Copy the output (starts with `hsapi_...`) and save it. You cannot retrieve it again.

### Option B: kubectl exec (TrueNAS Scale uses k3s)

From a machine that can reach TrueNAS and has `kubectl` configured for the cluster:

```bash
# Find the headscale pod and namespace (adjust if your app name/namespace differ)
kubectl get pods -A | grep headscale

# Run the command (replace NAMESPACE and POD with actual values)
kubectl exec -it -n NAMESPACE POD -- headscale apikeys create --expiration 90d
```

### Option C: One-off container exec via TrueNAS UI

Some TrueNAS app UIs let you "Run a command" in the container. Use the same command as Option A.

## 4. Configure the CLI

```bash
cp ~/dotfiles/headscale/.env.example ~/dotfiles/headscale/.env
```

Edit `~/dotfiles/headscale/.env`:

- **HEADSCALE_CLI_ADDRESS:** `192.168.0.158:50443` (your TrueNAS IP and gRPC port). If the app uses a different port, change it.
- **HEADSCALE_CLI_API_KEY:** Paste the API key from step 3.
- **HEADSCALE_CLI_INSECURE:** `1` for LAN-only without trusted TLS (self-signed or no cert).

Reload your shell or run `source ~/.zshrc` so the env vars are picked up.

## 5. Test

```bash
headscale nodes list
headscale users list
```

If you see output, the CLI is connected.

## Common Commands (Phase 0 for UDM Pro Subnet Router)

```bash
# Create user for the router
headscale users create udmpro

# Create pre-auth key (copy and save the output)
headscale preauthkeys create --user udmpro --reusable --expiration 24h

# Later: list routes, approve routes
headscale nodes list-routes
headscale nodes approve-routes --identifier <NODE_ID> --routes 192.168.1.0/24
```

## Aliases (from .zshrc)

- `headscale-users` → `headscale users list`
- `headscale-nodes` → `headscale nodes list`
- `headscale-routes` → `headscale nodes list-routes`

## Troubleshooting

- **"connection refused"** → gRPC port 50443 may not be exposed. Add it in the TrueNAS app or try the HTTP port (30210) if the CLI supports it.
- **"permission denied" / auth error** → API key missing or expired. Create a new key and update `.env`.
- **Certificate errors** → Set `HEADSCALE_CLI_INSECURE=1` for LAN-only, or add the server's cert to your trust store.
