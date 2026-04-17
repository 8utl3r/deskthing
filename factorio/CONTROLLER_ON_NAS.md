# Put the Controller on the NAS (Path B – no registry)

**App definition:** **`truenas_controller_app_volume.yaml`** (in this directory). Use this file when you install or update the "controller" app in TrueNAS.

Use this only if you **don’t** build/push an image (Path A in **CONTROLLER_DEPLOY.md** is preferred).

With this path, the app expects controller files at `/mnt/boot-pool/apps/factorio-controller/`. If they’re missing, the container starts, tries to run `python3 factorio_http_controller.py`, and exits immediately (no stats or logs).

---

## If you still see "Factorio NPC Controller with n8n Backend" in logs

The container is running the **old** controller. The new one is **Factorio HTTP Controller** and does reference-data caching. To switch:

1. **Push the new controller** from your Mac:
   ```bash
   cd /Users/pete/dotfiles/factorio
   ./push_controller_to_nas.sh
   ```
   When prompted, enter your NAS sudo password so the files can be copied into `/mnt/boot-pool/apps/factorio-controller/`.

2. **Ensure the app runs the new script**  
   The app command must be `python3 -u factorio_http_controller.py`.  
   - In TrueNAS: **Apps → Installed Apps → controller → Edit** (or Upgrade).  
   - Check the **command** / workload args. If it still says `factorio_n8n_controller.py`, change it to `factorio_http_controller.py` and save.  
   - If you manage the app via YAML, re-apply **truenas_controller_app_volume.yaml** (it already uses `factorio_http_controller.py`).

3. **Restart the app**  
   **Apps → Installed Apps → controller → Restart**.

   **If Restart fails** (e.g. `[EFAULT] Failed 'up' action for 'controller' app` or "removal of container ... is already in progress"):
   - Check `/var/log/app_lifecycle.log` on the NAS for the exact error.
   - SSH to the NAS: `ssh truenas_admin@192.168.0.158`
   - List containers: `sudo k3s crictl ps -a | grep -i controller` (TrueNAS Scale uses k3s; if using Docker: `docker ps -a`)
   - Force-remove the stuck controller container:  
     - k3s: `sudo k3s crictl rm -f <container_id>`  
     - Docker: `sudo docker rm -f <container_id_or_name>`
   - In TrueNAS UI: **Apps → controller → Start** (or Upgrade then Start).
   - **Non-interactive:** Create `factorio/.env.nas` (gitignored) with one line, e.g. `NAS_SUDO_PASSWORD='12345678'`. Then from `factorio/`: `./nas_sudo.sh docker ps -a` or `./nas_sudo.sh docker rm -f <id>`. **Starting** the app after removal: use the TrueNAS UI (**Apps → controller → Start**); `midclt` app-start methods are not available the same way on TrueNAS 25.04.

4. **Confirm in logs**  
   You should see:
   - `Factorio HTTP Controller`
   - `Reference data: /app/.reference_data` (or similar)
   - After the first RCON use: `📦 Wrote reference data: ...` for recipes/technologies.

Do the steps below **before** installing the app from **truenas_controller_app_volume.yaml**.

---

## Step 1: Create the directory on the NAS

SSH into the NAS (or use TrueNAS Shell):

```bash
ssh truenas_admin@192.168.0.158
```

Then:

```bash
sudo mkdir -p /mnt/boot-pool/apps/factorio-controller
sudo mkdir -p /mnt/boot-pool/apps/factorio-controller/logs
sudo chown -R 568:568 /mnt/boot-pool/apps/factorio-controller
```

(568 is often the `apps` user/group on TrueNAS; if your NAS uses something else, use that.)

---

## Step 2: Copy the controller files from your Mac

From your Mac (in a terminal):

```bash
cd /Users/pete/dotfiles/factorio

scp factorio_http_controller.py config.py requirements.txt truenas_admin@192.168.0.158:/tmp/
```

Then on the NAS:

```bash
sudo mv /tmp/factorio_http_controller.py /tmp/config.py /tmp/requirements.txt /mnt/boot-pool/apps/factorio-controller/
sudo chown 568:568 /mnt/boot-pool/apps/factorio-controller/*
```

---

## Step 3: (Optional) Point config at Mac Ollama

If Ollama still runs on your Mac, on the NAS run:

```bash
sudo sed -i 's/OLLAMA_HOST = "localhost"/OLLAMA_HOST = "192.168.0.30"/' /mnt/boot-pool/apps/factorio-controller/config.py
```

If you’re not using Ollama from the controller yet, you can skip this.

---

## Step 4: Confirm the files are there

On the NAS:

```bash
ls -la /mnt/boot-pool/apps/factorio-controller/
```

You should see at least:

- `factorio_http_controller.py`
- `config.py`
- `requirements.txt`

---

## Step 5: Deploy the app in TrueNAS

1. Apps → Discover Apps → ⋮ → **Install via YAML**
2. Application name: **controller**
3. Paste the contents of **truenas_controller_app_volume.yaml** (not the image-based one)
4. Deploy

The app will:

- Mount `/mnt/boot-pool/apps/factorio-controller` as `/app` in the container
- Run `pip install -r requirements.txt` then `python3 factorio_http_controller.py`
- Use host network so n8n can call `http://localhost:8080/execute-action`

---

## If you prefer one script from the Mac

You can do Step 1 (mkdir/chown) and Step 2 (scp + mv) from the Mac by SSH’ing and using sudo there. For example, from the Mac:

```bash
cd /Users/pete/dotfiles/factorio

# Copy to NAS /tmp
scp factorio_http_controller.py config.py requirements.txt truenas_admin@192.168.0.158:/tmp/

# Create dir and move files (will prompt for sudo password on NAS)
ssh truenas_admin@192.168.0.158 'sudo mkdir -p /mnt/boot-pool/apps/factorio-controller/logs && sudo chown -R 568:568 /mnt/boot-pool/apps/factorio-controller && sudo mv /tmp/factorio_http_controller.py /tmp/config.py /tmp/requirements.txt /mnt/boot-pool/apps/factorio-controller/ && sudo chown 568:568 /mnt/boot-pool/apps/factorio-controller/* && ls -la /mnt/boot-pool/apps/factorio-controller/'
```

Then do Step 4 and Step 5 as above.

---

## Summary

- The YAML does **not** put the controller code on the NAS.
- It only runs what’s already in `/mnt/boot-pool/apps/factorio-controller/`.
- You must copy `factorio_http_controller.py`, `config.py`, and `requirements.txt` there (and create the directory) before installing the app.

---

## Updating the controller

To push changes without manual scp: run **`./push_controller_to_nas.sh`** from the `factorio` dir on your Mac, then restart the **controller** app in TrueNAS. See **CONTROLLER_UPDATE_OPTIONS.md** for this and other update workflows.
