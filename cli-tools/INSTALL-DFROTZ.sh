#!/usr/bin/env bash
set -euo pipefail
ZORKS_DF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_DF_DIR/../versions.env"
source "$ZORKS_DF_DIR/../prog-langs/_common.bash"
zorks_dev_detect_host
if [[ "$ZORKS_DEV_OS" == win ]]; then
  ZORKS_DF_HOME="$ZORKS_DF_DIR/dfrotz-win64"
  [[ ! -x "$ZORKS_DF_HOME/dfrotz.exe" ]] || { printf 'dfrotz is already installed.\n'; exit 0; }
  ZORKS_DF_ARCHIVE="$ZORKS_DF_DIR/downloads/dfrotz.zip"
  [[ -s "$ZORKS_DF_ARCHIVE" ]] || zorks_dev_download 'https://www.ifarchive.org/if-archive/infocom/interpreters/frotz/dfrotz.zip' "$ZORKS_DF_ARCHIVE"
  mkdir -p "$ZORKS_DF_HOME"
  zorks_dev_extract_archive "$ZORKS_DF_ARCHIVE" "$ZORKS_DF_HOME"
  [[ -f "$ZORKS_DF_HOME/dfrotz.exe" ]] || zorks_dev_die 'dfrotz.exe was not found in the Windows package'
  chmod +x "$ZORKS_DF_HOME/dfrotz.exe"
else
  ZORKS_DF_HOME="$ZORKS_DF_DIR/dfrotz-$ZORKS_DEV_OS-$ZORKS_DEV_ARCH"
  [[ ! -x "$ZORKS_DF_HOME/dfrotz" ]] || { printf 'dfrotz is already installed.\n'; exit 0; }
  # An existing system installation is also sufficient; no sudo is needed.
  if command -v dfrotz >/dev/null 2>&1; then
    printf 'Using dfrotz already on PATH: %s\n' "$(command -v dfrotz)"; exit 0
  fi
  command -v make >/dev/null 2>&1 || zorks_dev_die 'Building dfrotz requires make and a C compiler (or install dfrotz separately)'
  command -v "${CC:-cc}" >/dev/null 2>&1 || zorks_dev_die 'Building dfrotz requires a C compiler; set CC if needed'
  ZORKS_DF_ARCHIVE="$ZORKS_DF_DIR/downloads/frotz-$ZORKS_FROTZ_VERSION.tar.gz"
  [[ -s "$ZORKS_DF_ARCHIVE" ]] || zorks_dev_download "https://gitlab.com/DavidGriffith/frotz/-/archive/$ZORKS_FROTZ_VERSION/frotz-$ZORKS_FROTZ_VERSION.tar.gz" "$ZORKS_DF_ARCHIVE"
  [[ "$(zorks_dev_sha256 "$ZORKS_DF_ARCHIVE")" == "$ZORKS_FROTZ_SHA256" ]] || zorks_dev_die "Frotz checksum mismatch; remove $ZORKS_DF_ARCHIVE and retry"
  ZORKS_DF_STAGE="$(mktemp -d "$ZORKS_DF_DIR/.dfrotz-build.XXXXXX")"
  trap 'rm -rf -- "$ZORKS_DF_STAGE"' EXIT
  tar --no-same-owner -xzf "$ZORKS_DF_ARCHIVE" -C "$ZORKS_DF_STAGE" --strip-components=1
  make -C "$ZORKS_DF_STAGE" dumb "CC=${CC:-cc}"
  [[ -x "$ZORKS_DF_STAGE/dfrotz" ]] || zorks_dev_die 'Building dfrotz did not produce an executable'
  mkdir -p "$ZORKS_DF_HOME"
  cp "$ZORKS_DF_STAGE/dfrotz" "$ZORKS_DF_HOME/dfrotz"
  for ZORKS_DF_LICENSE in COPYING LICENSE; do
    if [[ -f "$ZORKS_DF_STAGE/$ZORKS_DF_LICENSE" ]]; then cp "$ZORKS_DF_STAGE/$ZORKS_DF_LICENSE" "$ZORKS_DF_HOME/"; fi
  done
fi
printf 'Installed dfrotz in %s\n' "$ZORKS_DF_HOME"
