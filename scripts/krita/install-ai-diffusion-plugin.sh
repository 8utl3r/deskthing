#!/usr/bin/env bash
# Install or update Krita AI Diffusion plugin and open Krita for in-app steps.
# Usage: ./install-ai-diffusion-plugin.sh [--update]
# With --update: re-download latest plugin ZIP before opening Krita.

set -e
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PLUGIN_DIR="$DOTFILES/downloads/krita-ai-diffusion"
RELEASE_URL="https://github.com/Acly/krita-ai-diffusion/releases/latest"

get_latest_zip_url() {
  local tag_url
  tag_url=$(curl -sL -o /dev/null -w "%{url_effective}" "$RELEASE_URL")
  # e.g. .../tag/v1.47.0 -> v1.47.0
  local version="${tag_url##*/}"
  echo "https://github.com/Acly/krita-ai-diffusion/releases/download/${version}/krita_ai_diffusion-${version#v}.zip"
}

download_plugin() {
  mkdir -p "$PLUGIN_DIR"
  local zip_url
  zip_url=$(get_latest_zip_url)
  local filename="${zip_url##*/}"
  echo "Downloading $filename ..."
  curl -sL -o "$PLUGIN_DIR/$filename" "$zip_url"
  echo "$PLUGIN_DIR/$filename"
}

# --- main
UPDATE=false
for arg in "$@"; do
  [[ "$arg" == "--update" ]] && UPDATE=true
done

ZIP_PATH=""
if [[ -n "$(find "$PLUGIN_DIR" -maxdepth 1 -name 'krita_ai_diffusion-*.zip' 2>/dev/null)" ]]; then
  # use newest zip present
  ZIP_PATH=$(find "$PLUGIN_DIR" -maxdepth 1 -name 'krita_ai_diffusion-*.zip' -print0 | xargs -0 ls -t 2>/dev/null | head -1)
fi

if [[ "$UPDATE" == true || -z "$ZIP_PATH" || ! -f "$ZIP_PATH" ]]; then
  ZIP_PATH=$(download_plugin)
fi

echo ""
echo "Plugin ZIP ready: $ZIP_PATH"
echo ""
echo "In Krita, do the following (one-time):"
echo "  1. Tools → Scripts → Import Python Plugin from File…"
echo "     → Select: $ZIP_PATH"
echo "     → Enable when prompted, then restart Krita."
echo "  2. Settings → Dockers → ☑ AI Image Generation"
echo "  3. In the docker, click Configure → choose backend (Online / Local / ComfyUI)."
echo ""
read -r -p "Open Krita now? [Y/n] " reply
if [[ -z "$reply" || "$reply" =~ ^[Yy] ]]; then
  open -a Krita
fi
