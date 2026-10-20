#!/usr/bin/env bash
# Source this file from a shell; it activates the project-local Python venv.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file rather than executing it.\n' >&2
  exit 1
fi
ZORKS_PY_ACTIVATE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ZORKS_PY_ACTIVATE_ROOT="$(cd -- "$ZORKS_PY_ACTIVATE_DIR/.." && pwd -P)"
source "$ZORKS_PY_ACTIVATE_ROOT/versions.env" || return 1
source "$ZORKS_PY_ACTIVATE_DIR/_common.bash"
zorks_dev_detect_host || return 1
ZORKS_PY_ACTIVATE_VENV="$ZORKS_PY_ACTIVATE_DIR/$ZORKS_PYTHON_VENV"
if [[ "$ZORKS_DEV_OS" == win ]]; then
  ZORKS_PY_ACTIVATE_FILE="$ZORKS_PY_ACTIVATE_VENV/Scripts/activate"
else
  ZORKS_PY_ACTIVATE_FILE="$ZORKS_PY_ACTIVATE_VENV/bin/activate"
fi
if [[ ! -f "$ZORKS_PY_ACTIVATE_FILE" ]]; then
  printf 'Python is not installed. Run %s/INSTALL-DEV-TOOLS-ALL.sh\n' "$ZORKS_PY_ACTIVATE_ROOT" >&2
  return 1
fi
# Always source the target activation script: the install may have been moved,
# or another checkout may have a venv with the same basename.
if [[ -n "${VIRTUAL_ENV:-}" ]] && declare -F deactivate >/dev/null; then
  deactivate
fi
source "$ZORKS_PY_ACTIVATE_FILE" || return 1
export ZUI_PYTHON_VENV="$ZORKS_PY_ACTIVATE_VENV"
unset ZORKS_PY_ACTIVATE_DIR ZORKS_PY_ACTIVATE_ROOT
unset ZORKS_PY_ACTIVATE_VENV ZORKS_PY_ACTIVATE_FILE
