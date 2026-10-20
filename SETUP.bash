#!/usr/bin/env bash
# Activate this checkout without changing directories or shell options.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file: source %q\n' "$0" >&2
  exit 1
fi
case "${1:-}" in
  --windows-exact) export ZORKS_COMFYUI_PROFILE=windows-exact VENV_DIR=python-for-zork-win11-exact ;;
  --portable) export ZORKS_COMFYUI_PROFILE=portable VENV_DIR=python-for-zork ;;
esac
ZORKS_SETUP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# Activate Python first: deactivating a previous venv restores its old PATH.
# Prepend this checkout's Node/ZILF paths after that restoration.
source "$ZORKS_SETUP_ROOT/prog-langs/_common.bash" || return 1
zorks_dev_detect_host || return 1
zorks_dev_resolve_comfyui_profile || return 1
source "$ZORKS_SETUP_ROOT/prog-langs/ACTIVATE-PYTHON.bash" || return 1
export VENV_DIR="$ZORKS_PYTHON_VENV"
source "$ZORKS_SETUP_ROOT/prog-langs/SETUP.bash" || return 1
source "$ZORKS_SETUP_ROOT/cli-tools/SETUP.bash" || return 1
printf 'Activated Node.js %s; Python %s (%s)\n' "$(node --version)" "$(python --version 2>&1)" "$ZORKS_PYTHON_VENV"
unset ZORKS_SETUP_ROOT
