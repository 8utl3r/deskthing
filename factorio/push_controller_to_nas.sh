#!/bin/bash
# Push controller files to the NAS and optionally restart the app.
# Usage: ./push_controller_to_nas.sh [--restart]
#
# After running: restart the "controller" app in TrueNAS (Installed Apps → controller → Restart)
# if you pass --restart we attempt to redeploy via midclt (may need auth).

set -e
cd "$(dirname "$0")"

NAS="${NAS_USER:-truenas_admin}@${NAS_HOST:-192.168.0.158}"
REMOTE_DIR="/mnt/boot-pool/apps/factorio-controller"
STAGING="/tmp/factorio-controller-push-$$"

do_restart=false
[[ "${1:-}" == "--restart" ]] && do_restart=true

echo "Pushing controller files to NAS..."

# Stage in /tmp on NAS, then copy into app dir (needs sudo)
ssh "$NAS" "mkdir -p $STAGING"
rsync -avz \
  factorio_http_controller.py config.py requirements.txt \
  "$NAS:$STAGING/"

# -t so sudo can prompt for password if needed. Write under both names so app works whether it runs factorio_http_controller.py or factorio_n8n_controller.py.
ssh -t "$NAS" "sudo cp -f $STAGING/factorio_http_controller.py $STAGING/config.py $STAGING/requirements.txt $REMOTE_DIR/ && \
  sudo cp -f $REMOTE_DIR/factorio_http_controller.py $REMOTE_DIR/factorio_n8n_controller.py && \
  sudo chown 568:568 $REMOTE_DIR/factorio_http_controller.py $REMOTE_DIR/factorio_n8n_controller.py $REMOTE_DIR/config.py $REMOTE_DIR/requirements.txt && \
  rm -rf $STAGING"

echo "Done. Files are in $REMOTE_DIR on the NAS."
echo ""
echo "Contents of $REMOTE_DIR on NAS:"
ssh "$NAS" "ls -la $REMOTE_DIR"

if [[ "$do_restart" == "true" ]]; then
  echo "Attempting to restart controller app..."
  if ssh "$NAS" "sudo midclt call chart.release.redeploy '{\"release_name\":\"controller\"}'" 2>/dev/null; then
    echo "Restart triggered."
  else
    echo "Could not restart via API. Restart manually: TrueNAS → Apps → Installed Apps → controller → Restart"
  fi
else
  echo "Restart the controller app in TrueNAS: Apps → Installed Apps → controller → Restart"
fi
