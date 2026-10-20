#!/usr/bin/env bash
set -euo pipefail
ZORKS_INSTALL_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
usage() {
  cat <<'HELP'
Usage: ./dev/INSTALL-DEV-TOOLS-ALL.sh [options]
Default: languages, dfrotz, ZILF, llama.cpp + model, ComfyUI + models, Stable Audio.
  --portable              Regular packages selected for Python/CPU/GPU (default).
  --windows-exact         Reproduce the Windows 11 package snapshot in its own venv.
  --minimal               Install Node.js/pnpm, Python utilities and dfrotz only.
  --without-models        Skip GGUF and ComfyUI model downloads.
  --without-llama         Skip llama.cpp and its GGUF model.
  --without-comfyui       Skip ComfyUI, PyTorch and illustration models.
  --without-stableaudio   Skip the separate Stable Audio environment.
  --without-zilf          Skip the optional ZIL compiler.
  -h, --help              Show this message without installing anything.
Environment:
  ZORKS_COMFYUI_PROFILE=portable|windows-exact (default: portable)
  ZORKS_TORCH_BACKEND=auto|cpu|cu126|cu128|cu130 (portable profile)
  ZORKS_LLAMA_CPP_INSTALL_MODE=auto|binary|source (default: auto)
  ZORKS_LLAMA_BUILD_JOBS=2   Parallel jobs for a local Linux source build.
  HF_TOKEN=...             Optional Hugging Face credentials for downloads.
HELP
}
ZORKS_INSTALL_LLAMA=1 ZORKS_INSTALL_COMFY=1 ZORKS_INSTALL_AUDIO=1 ZORKS_INSTALL_ZILF=1 ZORKS_INSTALL_MODELS=1
for ZORKS_INSTALL_ARG in "$@"; do
  case "$ZORKS_INSTALL_ARG" in
    --portable) export ZORKS_COMFYUI_PROFILE=portable VENV_DIR=python-for-zork ;;
    --windows-exact) export ZORKS_COMFYUI_PROFILE=windows-exact VENV_DIR=python-for-zork-win11-exact ;;
    --minimal) ZORKS_INSTALL_LLAMA=0; ZORKS_INSTALL_COMFY=0; ZORKS_INSTALL_AUDIO=0; ZORKS_INSTALL_ZILF=0; ZORKS_INSTALL_MODELS=0 ;;
    --without-models) ZORKS_INSTALL_MODELS=0 ;;
    --without-llama) ZORKS_INSTALL_LLAMA=0 ;;
    --without-comfyui) ZORKS_INSTALL_COMFY=0 ;;
    --without-stableaudio) ZORKS_INSTALL_AUDIO=0 ;;
    --without-zilf) ZORKS_INSTALL_ZILF=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$ZORKS_INSTALL_ARG" >&2; usage >&2; exit 2 ;;
  esac
done
source "$ZORKS_INSTALL_ROOT/versions.env"
source "$ZORKS_INSTALL_ROOT/prog-langs/_common.bash"
zorks_dev_detect_host
zorks_dev_resolve_comfyui_profile
printf 'Installation profile: %s; Python environment: %s\n' "$ZORKS_DEV_COMFYUI_PROFILE" "$ZORKS_PYTHON_VENV"
"$ZORKS_INSTALL_ROOT/prog-langs/INSTALL-NODEJS.sh"
source "$ZORKS_INSTALL_ROOT/prog-langs/ACTIVATE-NODEJS.bash"
mkdir -p "$COREPACK_HOME"
command -v corepack >/dev/null 2>&1 || { printf 'Corepack was not found in the installed Node.js.\n' >&2; exit 1; }
corepack enable --install-directory "$ZORKS_DEV_NODE_BIN_DIR"
corepack prepare "pnpm@$ZORKS_PNPM_VERSION" --activate
hash -r
[[ "$(node --version)" == "v$ZORKS_NODE_VERSION" ]]
[[ "$(pnpm --version)" == "$ZORKS_PNPM_VERSION" ]]
"$ZORKS_INSTALL_ROOT/prog-langs/INSTALL-PYTHON.sh"
"$ZORKS_INSTALL_ROOT/cli-tools/INSTALL-DFROTZ.sh"
if (( ZORKS_INSTALL_ZILF )); then "$ZORKS_INSTALL_ROOT/prog-langs/INSTALL-ZILF.sh"; fi
if (( ZORKS_INSTALL_LLAMA )); then
  "$ZORKS_INSTALL_ROOT/cli-tools/GET-LLAMA-CPP.sh"
  if (( ZORKS_INSTALL_MODELS )); then "$ZORKS_INSTALL_ROOT/cli-tools/GET-LLAMA-CPP-MODEL.sh"; fi
fi
if (( ZORKS_INSTALL_COMFY )); then
  "$ZORKS_INSTALL_ROOT/cli-tools/INSTALL-COMFYUI.sh"
  "$ZORKS_INSTALL_ROOT/cli-tools/PIP-INSTALL-FOR-COMFYUI.sh"
  if (( ZORKS_INSTALL_MODELS )); then "$ZORKS_INSTALL_ROOT/cli-tools/DOWNLOAD-MODELS-FOR-COMFYUI.sh"; fi
fi
if (( ZORKS_INSTALL_AUDIO )); then
  VENV_DIR=python-for-stableaudio "$ZORKS_INSTALL_ROOT/prog-langs/INSTALL-PYTHON.sh"
  VENV_DIR=python-for-stableaudio "$ZORKS_INSTALL_ROOT/prog-langs/PIP-INSTALL-STABLEAUDIO.sh"
fi
if [[ "$ZORKS_DEV_COMFYUI_PROFILE" == windows-exact ]]; then
  printf '\nWindows snapshot tools are ready. Activate in each new Bash shell:\n  source %q/SETUP.bash --windows-exact\n' "$ZORKS_INSTALL_ROOT"
else
  printf '\nDevelopment tools are ready. Activate in each new Bash shell:\n  source %q/SETUP.bash --portable\n' "$ZORKS_INSTALL_ROOT"
fi
