#!/usr/bin/env bash
set -euo pipefail
ZORKS_COMFY_PIP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_COMFY_PIP_DIR/../versions.env"
source "$ZORKS_COMFY_PIP_DIR/../prog-langs/_common.bash"
zorks_dev_detect_host
ZORKS_COMFY_PY="$(zorks_dev_python_executable "$(cd -- "$ZORKS_COMFY_PIP_DIR/.." && pwd -P)")"
[[ -x "$ZORKS_COMFY_PY" ]] || zorks_dev_die 'Install the project Python environment first'
[[ -f "$ZORKS_COMFY_PIP_DIR/ComfyUI/requirements.txt" ]] || zorks_dev_die 'Run cli-tools/INSTALL-COMFYUI.sh first'
zorks_dev_resolve_comfyui_profile
if [[ "$ZORKS_DEV_COMFYUI_PROFILE" == windows-exact ]]; then
  # No generic torch installation or unpinned requirements pass may precede or
  # follow this full snapshot replay.
  "$ZORKS_COMFY_PIP_DIR/INSTALL-WINDOWS-COMFYUI-SNAPSHOT.sh"
  printf 'Windows ComfyUI snapshot is ready. Download models with cli-tools/DOWNLOAD-MODELS-FOR-COMFYUI.sh\n'
  exit 0
fi
"$ZORKS_COMFY_PIP_DIR/../prog-langs/PIP-INSTALL-PYTORCH.sh"
# Constrain the requirements pass so it cannot silently replace the selected
# CPU/CUDA/MPS torch family with a different one from the default package index.
ZORKS_COMFY_CONSTRAINTS="$(mktemp "$ZORKS_COMFY_PIP_DIR/.torch-constraints.XXXXXX")"
trap 'rm -f -- "$ZORKS_COMFY_CONSTRAINTS"' EXIT
"$ZORKS_COMFY_PY" -m pip freeze | awk '/^(torch|torchvision|torchaudio)==/' > "$ZORKS_COMFY_CONSTRAINTS"
"$ZORKS_COMFY_PY" -m pip install -c "$ZORKS_COMFY_CONSTRAINTS" -r "$ZORKS_COMFY_PIP_DIR/ComfyUI/requirements.txt"
"$ZORKS_COMFY_PY" -m pip install PyOpenGL glfw huggingface_hub hf-xet
"$ZORKS_COMFY_PY" -m pip check
printf 'ComfyUI dependencies installed. Download models with cli-tools/DOWNLOAD-MODELS-FOR-COMFYUI.sh\n'
