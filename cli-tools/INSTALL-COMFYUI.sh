#!/usr/bin/env bash
set -euo pipefail
ZORKS_COMFY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_COMFY_DIR/../versions.env"
source "$ZORKS_COMFY_DIR/../prog-langs/_common.bash"
if [[ -f "$ZORKS_COMFY_DIR/ComfyUI/requirements.txt" ]]; then
  printf 'Using existing ComfyUI source in %s/ComfyUI\n' "$ZORKS_COMFY_DIR"; exit 0
fi
[[ ! -e "$ZORKS_COMFY_DIR/ComfyUI" ]] || zorks_dev_die 'ComfyUI exists without requirements.txt; move it aside and retry'
ZORKS_COMFY_ARCHIVE="$ZORKS_COMFY_DIR/downloads/ComfyUI-$ZORKS_COMFYUI_VERSION.tar.gz"
[[ -s "$ZORKS_COMFY_ARCHIVE" ]] || zorks_dev_download "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v$ZORKS_COMFYUI_VERSION.tar.gz" "$ZORKS_COMFY_ARCHIVE"
ZORKS_COMFY_STAGE="$(mktemp -d "$ZORKS_COMFY_DIR/.comfyui-install.XXXXXX")"
trap 'rm -rf -- "$ZORKS_COMFY_STAGE"' EXIT
tar --no-same-owner -xzf "$ZORKS_COMFY_ARCHIVE" -C "$ZORKS_COMFY_STAGE"
[[ -f "$ZORKS_COMFY_STAGE/ComfyUI-$ZORKS_COMFYUI_VERSION/requirements.txt" ]] || zorks_dev_die 'Downloaded ComfyUI package is incomplete'
zorks_dev_move_with_retry "$ZORKS_COMFY_STAGE/ComfyUI-$ZORKS_COMFYUI_VERSION" "$ZORKS_COMFY_DIR/ComfyUI"
printf 'Installed ComfyUI source. Run %s/PIP-INSTALL-FOR-COMFYUI.sh\n' "$ZORKS_COMFY_DIR"
