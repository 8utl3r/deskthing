#!/bin/bash
# Build and optionally push the Factorio controller image for TrueNAS.
# Usage:
#   ./build_controller_image.sh              # build only (tag: factorio-controller:latest)
#   ./build_controller_image.sh push USER    # build and push to Docker Hub as USER/factorio-controller:latest

set -e
cd "$(dirname "$0")"

echo "Building Factorio controller image..."
docker build -f Dockerfile.controller -t factorio-controller:latest .

if [[ "${1:-}" == "push" && -n "${2:-}" ]]; then
  user="$2"
  docker tag factorio-controller:latest "$user/factorio-controller:latest"
  echo "Pushing to Docker Hub as $user/factorio-controller:latest ..."
  docker push "$user/factorio-controller:latest"
  echo "Done. In truenas_controller_app.yaml set: image: $user/factorio-controller:latest"
fi
