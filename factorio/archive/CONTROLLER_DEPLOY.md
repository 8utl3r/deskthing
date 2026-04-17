# Deploying the Factorio Controller the Right Way

The controller is built to run as a **self-contained container** with **config from env vars** (no copying Python files onto the NAS). Use one of these two paths.

---

## Path A: Image-based (recommended)

**Idea:** Build an image that includes the controller, push it to a registry, run it on TrueNAS with env-only config. No host mounts for code.

### 1. Build the image

From your Mac (or any machine with Docker):

```bash
cd /Users/pete/dotfiles/factorio
./build_controller_image.sh
```

Or manually:
```bash
docker build -f Dockerfile.controller -t factorio-controller:latest .
```

### 2. Push to a registry

Use Docker Hub (replace `YOUR_USER` with your Docker Hub username):

```bash
./build_controller_image.sh push YOUR_USER
```

Or manually:
```bash
docker login
docker tag factorio-controller:latest YOUR_USER/factorio-controller:latest
docker push YOUR_USER/factorio-controller:latest
```

### 3. Use the image in TrueNAS

1. Open **truenas_controller_app.yaml**.
2. Set **image** to your pushed image, for example:
   - `image: YOUR_USER/factorio-controller:latest`
   - or `image: docker.io/YOUR_USER/factorio-controller:latest`
3. Set **RCON_PASSWORD** in the env section to match your Factorio server.
4. In TrueNAS: **Apps → Discover Apps → ⋮ → Install via YAML**.
5. Application name: **controller**.
6. Paste the edited YAML and deploy.

The app uses **only** that image and env vars; no Python files need to exist on the NAS. Logs go to `/mnt/boot-pool/apps/factorio-controller-logs` if you keep the optional volume.

---

## Path B: No registry (copy source + run from host dir)

If you don’t use a registry, you can run from sources on the NAS by copying files and using a volume-based YAML.

**Steps:** Follow **CONTROLLER_ON_NAS.md**:

1. Create `/mnt/boot-pool/apps/factorio-controller/` on the NAS.
2. Copy **factorio_n8n_controller.py**, **config.py**, **requirements.txt** into that directory.
3. Use the **volume-based** app definition (see that file) that mounts that path and runs `pip install` + `python3 factorio_n8n_controller.py` inside the container.

Path B is more fragile (permissions, missing files) and is there only when you can’t use an image and a registry.

---

## Config (env vars)

When using the image (Path A), everything is configured via environment variables:

| Env var          | Meaning                      | Example / note                         |
|------------------|------------------------------|----------------------------------------|
| RCON_HOST        | Factorio server host         | `192.168.0.158`                        |
| RCON_PORT        | RCON port                    | `27015`                                |
| RCON_PASSWORD    | RCON password                | From Factorio/server config            |
| OLLAMA_HOST      | Ollama API host (optional)   | `192.168.0.30` if Ollama is on the Mac |
| OLLAMA_PORT      | Ollama API port              | `11434`                                |
| OLLAMA_MODEL     | Model name (optional)        | `phi3:mini`                            |

The controller reads these first; they override any values from **config.py** inside the image. That allows the same image to be used with different RCON/Ollama settings.

---

## Checks after deploy

- Container is running and restarts on failure.
- From the NAS (or from a host that shares its network):  
  `curl -s http://localhost:8080/health`
- n8n calls `http://localhost:8080/execute-action` (and uses host networking so “localhost” is the NAS).

If you use Path A and keep the logs volume, inspect logs under  
`/mnt/boot-pool/apps/factorio-controller-logs/` on the NAS when needed.
