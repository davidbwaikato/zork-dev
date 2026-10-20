#!/usr/bin/env bash
# Run this script (do not source); it never changes the calling shell.
set -euo pipefail
ZORKS_TORCH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_TORCH_DIR/../versions.env"
source "$ZORKS_TORCH_DIR/_common.bash"
zorks_dev_detect_host
ZORKS_TORCH_PY="$(zorks_dev_python_executable "$(cd -- "$ZORKS_TORCH_DIR/.." && pwd -P)")"
[[ -x "$ZORKS_TORCH_PY" ]] || zorks_dev_die 'Run prog-langs/INSTALL-PYTHON.sh first'
# Standalone Windows calls also honour the complete measured environment.
# Stable Audio always keeps its independent venv and version family.
if [[ "${ZORKS_TORCH_PROFILE:-}" != stableaudio ]]; then
  zorks_dev_resolve_comfyui_profile
  if [[ "$ZORKS_DEV_COMFYUI_PROFILE" == windows-exact ]]; then
    exec "$ZORKS_TORCH_DIR/../cli-tools/INSTALL-WINDOWS-COMFYUI-SNAPSHOT.sh"
  fi
fi
ZORKS_TORCH_SELECTION="${ZORKS_TORCH_BACKEND:-auto}"
if [[ "$ZORKS_TORCH_SELECTION" == auto ]]; then
  ZORKS_TORCH_SELECTION=cpu
  if [[ "$ZORKS_DEV_OS" == darwin ]]; then
    ZORKS_TORCH_SELECTION=mps
  elif command -v nvidia-smi >/dev/null 2>&1; then
    ZORKS_TORCH_CUDA="$(nvidia-smi 2>/dev/null | sed -n 's/.*CUDA Version: \([0-9]*\.[0-9]*\).*/\1/p' | head -n 1)" || ZORKS_TORCH_CUDA=''
    if [[ -n "$ZORKS_TORCH_CUDA" ]]; then
      ZORKS_TORCH_MAJOR="${ZORKS_TORCH_CUDA%%.*}"; ZORKS_TORCH_MINOR="${ZORKS_TORCH_CUDA#*.}"
      if (( ZORKS_TORCH_MAJOR >= 13 )); then ZORKS_TORCH_SELECTION=cu130
      elif (( ZORKS_TORCH_MAJOR == 12 && ZORKS_TORCH_MINOR >= 8 )); then ZORKS_TORCH_SELECTION=cu128
      elif (( ZORKS_TORCH_MAJOR == 12 && ZORKS_TORCH_MINOR >= 6 )); then ZORKS_TORCH_SELECTION=cu126
      fi
    fi
  fi
fi
# Let pip select wheels/dependencies compatible with the running Python from
# the chosen backend index. ComfyUI then constrains these installed versions.
ZORKS_TORCH_ARGS=(torch torchvision torchaudio)
case "$ZORKS_TORCH_SELECTION" in
  cpu) [[ "$ZORKS_DEV_OS" == darwin ]] || ZORKS_TORCH_ARGS+=(--index-url https://download.pytorch.org/whl/cpu) ;;
  mps) [[ "$ZORKS_DEV_OS" == darwin ]] || zorks_dev_die 'MPS requires macOS' ;;
  cu126|cu128|cu130)
    [[ "$ZORKS_DEV_OS" != darwin ]] || zorks_dev_die 'CUDA wheels are not available on macOS'
    ZORKS_TORCH_ARGS+=(--index-url "https://download.pytorch.org/whl/$ZORKS_TORCH_SELECTION") ;;
  *) zorks_dev_die "Unsupported ZORKS_TORCH_BACKEND: $ZORKS_TORCH_SELECTION" ;;
esac
# Stable Audio may request an independent version family and index.
if [[ "${ZORKS_TORCH_PROFILE:-}" == stableaudio ]]; then
  ZORKS_TORCH_ARGS=(torch==2.7.1 torchaudio==2.7.1)
  case "$ZORKS_TORCH_SELECTION" in
    cu130|cu128) ZORKS_TORCH_ARGS+=(--index-url https://download.pytorch.org/whl/cu128) ;;
    cu126) ZORKS_TORCH_ARGS+=(--index-url https://download.pytorch.org/whl/cu126) ;;
    cpu) [[ "$ZORKS_DEV_OS" == darwin ]] || ZORKS_TORCH_ARGS+=(--index-url https://download.pytorch.org/whl/cpu) ;;
  esac
fi
printf 'Installing PyTorch backend: %s\n' "$ZORKS_TORCH_SELECTION"
"$ZORKS_TORCH_PY" -m pip install "${ZORKS_TORCH_ARGS[@]}"
"$ZORKS_TORCH_PY" -c 'import torch; print("PyTorch:", torch.__version__); print("CUDA available:", torch.cuda.is_available()); print("MPS available:", bool(getattr(torch.backends, "mps", None) and torch.backends.mps.is_available()))'
