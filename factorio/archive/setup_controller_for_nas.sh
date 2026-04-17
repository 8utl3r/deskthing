#!/usr/bin/env bash
# One-shot setup: create dir on NAS and copy controller files. Run from Mac before first GUI install.
# Usage: ./setup_controller_for_nas.sh
# Env: NAS_HOST (default 192.168.0.158), NAS_USER (default truenas_admin)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

NAS="${NAS_USER:-truenas_admin}@${NAS_HOST:-192.168.0.158}"
REMOTE_DIR="/mnt/boot-pool/apps/factorio-controller"
STAGING="/tmp/factorio-controller-setup-$$"

echo "Setting up controller on NAS ($NAS)..."
echo "  Remote dir: $REMOTE_DIR"
echo ""

# Create dir on NAS
ssh "$NAS" "sudo mkdir -p $REMOTE_DIR $REMOTE_DIR/logs && sudo chown -R 568:568 $REMOTE_DIR"
echo "  Created $REMOTE_DIR (and logs/) with owner 568:568"

# Copy files to /tmp then move into place (needs sudo on NAS)
ssh "$NAS" "mkdir -p $STAGING"
rsync -avz factorio_n8n_controller.py config.py requirements.txt "$NAS:$STAGING/"
ssh "$NAS" "sudo cp -f $STAGING/factorio_n8n_controller.py $STAGING/config.py $STAGING/requirements.txt $REMOTE_DIR/ && \
  sudo chown 568:568 $REMOTE_DIR/factorio_n8n_controller.py $REMOTE_DIR/config.py $REMOTE_DIR/requirements.txt && \
  rm -rf $STAGING"

echo "  Copied factorio_n8n_controller.py, config.py, requirements.txt"
echo ""
echo "Verify on NAS:"
ssh "$NAS" "ls -la $REMOTE_DIR/"
echo ""
echo "Next: In TrueNAS go to Apps -> Discover Apps -> ⋮ -> Install via YAML"
echo "  Name: controller"
echo "  Custom Config: paste contents of factorio/truenas_controller_app_volume.yaml"
echo "  Then Save to deploy."
echo ""
echo "See controller_install_nas_now.md for full steps and wizard fallback."
