#!/usr/bin/env bash
# Download portable Python and create a Zorks Illustrated virtual environment.
set -euo pipefail
unset PYTHONHOME PYTHONPATH

ZORKS_PY_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ZORKS_PY_DEV_ROOT="$(cd -- "$ZORKS_PY_SCRIPT_DIR/.." && pwd -P)"
source "$ZORKS_PY_DEV_ROOT/versions.env"
source "$ZORKS_PY_SCRIPT_DIR/_common.bash"
zorks_dev_detect_host

case "$ZORKS_DEV_OS:$ZORKS_DEV_ARCH" in
  linux:x64) ZORKS_PY_TARGET=x86_64-unknown-linux-gnu ;;
  linux:arm64) ZORKS_PY_TARGET=aarch64-unknown-linux-gnu ;;
  darwin:x64) ZORKS_PY_TARGET=x86_64-apple-darwin ;;
  darwin:arm64) ZORKS_PY_TARGET=aarch64-apple-darwin ;;
  win:x64) ZORKS_PY_TARGET=x86_64-pc-windows-msvc ;;
  win:arm64) ZORKS_PY_TARGET=aarch64-pc-windows-msvc ;;
esac

ZORKS_PY_ARCHIVE="cpython-${ZORKS_PYTHON_VERSION}+${ZORKS_PYTHON_BUILD_RELEASE}-${ZORKS_PY_TARGET}-install_only_stripped.tar.gz"
ZORKS_PY_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${ZORKS_PYTHON_BUILD_RELEASE}/${ZORKS_PY_ARCHIVE}"
ZORKS_PY_CACHE="$ZORKS_PY_SCRIPT_DIR/downloads/python/$ZORKS_PY_ARCHIVE"
ZORKS_PY_CHECKSUMS="$ZORKS_PY_SCRIPT_DIR/downloads/python/SHA256SUMS-${ZORKS_PYTHON_BUILD_RELEASE}.txt"
ZORKS_PY_INSTALL="$ZORKS_PY_SCRIPT_DIR/installed/python-${ZORKS_PYTHON_VERSION}-${ZORKS_PY_TARGET}"
ZORKS_PY_VENV="$ZORKS_PY_SCRIPT_DIR/$ZORKS_PYTHON_VENV"
if [[ "$ZORKS_DEV_OS" == win ]]; then
  ZORKS_PY_BASE="$ZORKS_PY_INSTALL/python.exe"
  ZORKS_PY_VENV_EXE="$ZORKS_PY_VENV/Scripts/python.exe"
else
  ZORKS_PY_BASE="$ZORKS_PY_INSTALL/bin/python3"
  ZORKS_PY_VENV_EXE="$ZORKS_PY_VENV/bin/python"
fi

zorks_python_matches() {
  [[ -x "$1" ]] && [[ "$("$1" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null)" == "$ZORKS_PYTHON_VERSION" ]]
}

zorks_verify_python_archive() {
  local expected actual
  expected="$(awk -v name="$ZORKS_PY_ARCHIVE" '$2 == name || $2 == "*" name {print tolower($1); exit}' "$ZORKS_PY_CHECKSUMS")"
  [[ -n "$expected" ]] || { zorks_dev_die "No SHA-256 checksum found for $ZORKS_PY_ARCHIVE"; return 1; }
  actual="$(zorks_dev_sha256 "$ZORKS_PY_CACHE")" || return 1
  [[ "$actual" == "$expected" ]] || { zorks_dev_die "SHA-256 mismatch for $ZORKS_PY_ARCHIVE"; return 1; }
}

if ! zorks_python_matches "$ZORKS_PY_BASE"; then
  mkdir -p "$(dirname "$ZORKS_PY_CACHE")" "$(dirname "$ZORKS_PY_INSTALL")"
  if [[ ! -s "$ZORKS_PY_CHECKSUMS" ]]; then
    zorks_dev_download "https://github.com/astral-sh/python-build-standalone/releases/download/${ZORKS_PYTHON_BUILD_RELEASE}/SHA256SUMS" "$ZORKS_PY_CHECKSUMS"
  fi
  if [[ ! -s "$ZORKS_PY_CACHE" ]] || ! tar -tzf "$ZORKS_PY_CACHE" >/dev/null 2>&1; then
    rm -f -- "$ZORKS_PY_CACHE"
    printf 'Downloading portable Python %s for %s...\n' "$ZORKS_PYTHON_VERSION" "$ZORKS_PY_TARGET"
    zorks_dev_download "$ZORKS_PY_URL" "$ZORKS_PY_CACHE"
  fi
  if ! zorks_verify_python_archive; then
    printf 'Cached Python files failed verification; downloading them again.\n' >&2
    rm -f -- "$ZORKS_PY_CACHE" "$ZORKS_PY_CHECKSUMS"
    zorks_dev_download "https://github.com/astral-sh/python-build-standalone/releases/download/${ZORKS_PYTHON_BUILD_RELEASE}/SHA256SUMS" "$ZORKS_PY_CHECKSUMS"
    zorks_dev_download "$ZORKS_PY_URL" "$ZORKS_PY_CACHE"
    zorks_verify_python_archive
  fi
  tar -tzf "$ZORKS_PY_CACHE" >/dev/null
  ZORKS_PY_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/zorks-python.XXXXXX")"
  trap 'rm -rf -- "$ZORKS_PY_STAGE"' EXIT
  tar --no-same-owner -xzf "$ZORKS_PY_CACHE" -C "$ZORKS_PY_STAGE"
  [[ -d "$ZORKS_PY_STAGE/python" ]] || zorks_dev_die 'Python archive lacked python/'
  if [[ -e "$ZORKS_PY_INSTALL" ]]; then
    zorks_dev_move_with_retry "$ZORKS_PY_INSTALL" "${ZORKS_PY_INSTALL}.incomplete.$(date +%Y%m%d%H%M%S)"
  fi
  zorks_dev_move_with_retry "$ZORKS_PY_STAGE/python" "$ZORKS_PY_INSTALL"
  rm -rf -- "$ZORKS_PY_STAGE"
  trap - EXIT
  zorks_python_matches "$ZORKS_PY_BASE" || zorks_dev_die 'Installed Python failed its version check'
fi
printf 'Portable Python ready: %s\n' "$ZORKS_PY_BASE"

if ! zorks_python_matches "$ZORKS_PY_VENV_EXE"; then
  if [[ -e "$ZORKS_PY_VENV" ]]; then
    zorks_dev_move_with_retry "$ZORKS_PY_VENV" "${ZORKS_PY_VENV}.incomplete.$(date +%Y%m%d%H%M%S)"
  fi
  "$ZORKS_PY_BASE" -m venv "$ZORKS_PY_VENV"
fi
zorks_python_matches "$ZORKS_PY_VENV_EXE" || zorks_dev_die 'Virtual environment failed its version check'

if [[ "${ZORKS_COMFYUI_PROFILE:-portable}" == windows-exact && "$ZORKS_PYTHON_VENV" != python-for-stableaudio ]]; then
  printf 'Python ready for the Windows snapshot; shared utility packages will come from its recorded requirements.\n'
else
  "$ZORKS_PY_VENV_EXE" -m pip install -r "$ZORKS_PY_SCRIPT_DIR/python-requirements.txt"
fi
"$ZORKS_PY_VENV_EXE" -m pip check
printf 'Zorks Python environment ready: %s\n' "$ZORKS_PY_VENV"
