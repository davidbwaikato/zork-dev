#!/usr/bin/env bash
set -euo pipefail
ZORKS_DIFFUSERS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
"$ZORKS_DIFFUSERS_DIR/PIP-INSTALL-FOR-COMFYUI.sh"
source "$ZORKS_DIFFUSERS_DIR/../prog-langs/ACTIVATE-PYTHON.bash"
source "$ZORKS_DIFFUSERS_DIR/../prog-langs/_common.bash"
zorks_dev_detect_host
zorks_dev_resolve_comfyui_profile
if [[ "$ZORKS_DEV_COMFYUI_PROFILE" == windows-exact ]]; then
  # Optional extensions may add packages, but cannot change snapshot pins.
  python -m pip install -c "$ZORKS_DIFFUSERS_DIR/comfyui_exact_requirements_win64.txt" diffusers accelerate
  python -m pip check
else
  python -m pip install diffusers accelerate
  python -m pip check
fi
