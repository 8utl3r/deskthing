# Updating the Controller Without Copy-Paste

---

## Option 1: Push script (volume-based, one command)

If you use **truenas_controller_app_volume.yaml** (files on the NAS):

```bash
cd /Users/pete/dotfiles/factorio
./push_controller_to_nas.sh
```

That rsyncs `factorio_n8n_controller.py`, `config.py`, and `requirements.txt` to the NAS. Then restart the **controller** app in TrueNAS (Apps → Installed Apps → controller → Restart).

**Try auto-restart (may need TrueNAS API):**

```bash
./push_controller_to_nas.sh --restart
```

**Workflow:** Edit on Mac → run `./push_controller_to_nas.sh` → restart app in TrueNAS. No manual scp.

---

## Option 2: Git on the NAS (volume-based, pull on NAS)

1. **One-time:** On the NAS, clone your dotfiles into the controller app dir:

   ```bash
   ssh truenas_admin@192.168.0.158
   sudo rm -rf /mnt/boot-pool/apps/factorio-controller/*   # if you already copied files
   sudo git clone --depth 1 https://github.com/YOUR_USER/dotfiles.git /tmp/dotfiles
   sudo mkdir -p /mnt/boot-pool/apps/factorio-controller
   sudo cp /tmp/dotfiles/factorio/factorio_n8n_controller.py /tmp/dotfiles/factorio/config.py /tmp/dotfiles/factorio/requirements.txt /mnt/boot-pool/apps/factorio-controller/
   sudo chown -R 568:568 /mnt/boot-pool/apps/factorio-controller
   sudo rm -rf /tmp/dotfiles
   ```

   Or, if you prefer to keep a git checkout there:

   ```bash
   sudo git clone --depth 1 --filter=blob:none --sparse https://github.com/YOUR_USER/dotfiles.git /mnt/boot-pool/apps/factorio-controller-repo
   cd /mnt/boot-pool/apps/factorio-controller-repo
   sudo git sparse-checkout set factorio/factorio_n8n_controller.py factorio/config.py factorio/requirements.txt
   sudo ln -sf /mnt/boot-pool/apps/factorio-controller-repo/factorio/factorio_n8n_controller.py /mnt/boot-pool/apps/factorio-controller/
   # ... (symlinks for config.py, requirements.txt) – or use a small script to copy factorio/* into /mnt/boot-pool/apps/factorio-controller after pull
   ```

   Simpler: keep a **full clone** of the factorio folder and point the app at it:

   - Clone `dotfiles` to `/mnt/boot-pool/apps/factorio-controller-repo`.
   - In **truenas_controller_app_volume.yaml**, set:
     - `volumes: - /mnt/boot-pool/apps/factorio-controller-repo/factorio:/app`
   - And create the logs dir separately, e.g. `- /mnt/boot-pool/apps/factorio-controller-logs:/app/logs`.

2. **To update:** On the NAS:

   ```bash
   cd /mnt/boot-pool/apps/factorio-controller-repo && sudo git pull
   ```

   Then restart the **controller** app in TrueNAS.

**Workflow:** Edit on Mac → push to GitHub → on NAS `git pull` in the repo → restart app. No push script; NAS needs git.

---

## Option 3: Image-based (build, push, restart)

If you use **truenas_controller_app.yaml** with a registry (Docker Hub, GHCR, or a private registry on the NAS):

**Update flow:**

```bash
cd /Users/pete/dotfiles/factorio
./build_controller_image.sh push YOUR_DOCKERHUB_USER
```

Then in TrueNAS: Apps → Installed Apps → **controller** → **Restart** (or **Redeploy** so it pulls the new image).

**Workflow:** Edit on Mac → build + push image → restart (or redeploy) app. No file copy; all code lives in the image.

---

## Comparison

| Option | Needs on NAS | Update on Mac | Update on NAS |
|--------|--------------|---------------|---------------|
| **1. Push script** | Nothing extra | `./push_controller_to_nas.sh` then restart app | Restart app (UI) |
| **2. Git on NAS** | `git` + clone of repo | `git push` | `git pull` in repo, then restart app |
| **3. Image-based** | Nothing (pulls image) | `./build_controller_image.sh push USER` | Restart/redeploy app |

**Simplest for “no registry”:** use **Option 1** (`./push_controller_to_nas.sh`) and restart the app after each update.
