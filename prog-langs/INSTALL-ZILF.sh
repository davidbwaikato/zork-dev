#!/usr/bin/env bash
set -euo pipefail
ZORKS_ZILF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_ZILF_DIR/../versions.env"
source "$ZORKS_ZILF_DIR/_common.bash"
zorks_dev_detect_host
case "$ZORKS_DEV_OS:$ZORKS_DEV_ARCH" in
  linux:x64) ZORKS_ZILF_PLATFORM=linux-x64; ZORKS_ZILF_SHA=06ff0e59eff6e6896fd9ce71d16c100365abbc537cf030f2bd31beb9384d0155 ;;
  linux:arm64) ZORKS_ZILF_PLATFORM=linux-arm64; ZORKS_ZILF_SHA=adca948db3c0971b24d2002245e77a0321c072c9f62fb97945b7a874f7be6ed5 ;;
  darwin:arm64) ZORKS_ZILF_PLATFORM=osx-arm64; ZORKS_ZILF_SHA=a5bd632e80d03a5037d1ce04b4cdd55af938498010f37cf0ab4995b7d1125629 ;;
  win:x64) ZORKS_ZILF_PLATFORM=win-x64; ZORKS_ZILF_SHA=664b1e84a94def0ef67d5007e3a94ce720d546919d24cd5a19fc08d619a157a1 ;;
  *)
    if command -v zilf >/dev/null 2>&1; then printf 'Using ZILF already on PATH.\n'; exit 0; fi
    printf 'ZILF %s has no native archive for %s-%s.\n' "$ZORKS_ZILF_VERSION" "$ZORKS_DEV_OS" "$ZORKS_DEV_ARCH" >&2
    printf 'Skipping the optional compiler. Existing compiled Zork story files still run.\n' >&2
    printf 'For source builds, install the .NET 10 SDK and follow https://github.com/taradinoc/zilf\n' >&2
    exit 0 ;;
esac
ZORKS_ZILF_EXT=tar.gz
ZORKS_ZILF_EXE=zilf
[[ "$ZORKS_DEV_OS" != win ]] || { ZORKS_ZILF_EXT=zip; ZORKS_ZILF_EXE=zilf.exe; }
ZORKS_ZILF_NAME="zilf-$ZORKS_ZILF_VERSION-$ZORKS_ZILF_PLATFORM.$ZORKS_ZILF_EXT"
ZORKS_ZILF_CACHE="$ZORKS_ZILF_DIR/downloads/zilf/$ZORKS_ZILF_NAME"
ZORKS_ZILF_HOME="$ZORKS_ZILF_DIR/installed/zilf-$ZORKS_ZILF_VERSION-$ZORKS_DEV_OS-$ZORKS_DEV_ARCH"
if [[ -x "$ZORKS_ZILF_HOME/bin/$ZORKS_ZILF_EXE" ]]; then printf 'ZILF is already installed.\n'; exit 0; fi
[[ -s "$ZORKS_ZILF_CACHE" ]] || zorks_dev_download "https://github.com/taradinoc/zilf/releases/download/$ZORKS_ZILF_RELEASE/$ZORKS_ZILF_NAME" "$ZORKS_ZILF_CACHE"
[[ "$(zorks_dev_sha256 "$ZORKS_ZILF_CACHE")" == "$ZORKS_ZILF_SHA" ]] || zorks_dev_die "ZILF checksum mismatch; remove $ZORKS_ZILF_CACHE and retry"
ZORKS_ZILF_STAGE="$(mktemp -d "$ZORKS_ZILF_DIR/.zilf-install.XXXXXX")"
trap 'rm -rf -- "$ZORKS_ZILF_STAGE"' EXIT
zorks_dev_extract_archive "$ZORKS_ZILF_CACHE" "$ZORKS_ZILF_STAGE"
ZORKS_ZILF_FOUND="$(find "$ZORKS_ZILF_STAGE" -type f -name "$ZORKS_ZILF_EXE" -print -quit)"
[[ -n "$ZORKS_ZILF_FOUND" ]] || zorks_dev_die 'ZILF executable missing from downloaded package'
ZORKS_ZILF_PACKAGE="$(dirname "$ZORKS_ZILF_FOUND")"
if [[ "$(basename "$ZORKS_ZILF_PACKAGE")" == bin ]]; then ZORKS_ZILF_PACKAGE="$(dirname "$ZORKS_ZILF_PACKAGE")"; fi
if [[ -e "$ZORKS_ZILF_HOME" ]]; then
  zorks_dev_move_with_retry "$ZORKS_ZILF_HOME" "$ZORKS_ZILF_HOME.incomplete.$(date +%Y%m%d%H%M%S)"
fi
mkdir -p "$ZORKS_ZILF_HOME"
cp -R "$ZORKS_ZILF_PACKAGE/." "$ZORKS_ZILF_HOME/"
if [[ ! -d "$ZORKS_ZILF_HOME/bin" ]]; then
  # Current packages have bin/; accept a flat package without losing libraries.
  mkdir -p "$ZORKS_ZILF_HOME/bin"
  for ZORKS_ZILF_TOOL in zilf zapf; do
    [[ ! -f "$ZORKS_ZILF_HOME/$ZORKS_ZILF_TOOL" ]] || ln -s "../$ZORKS_ZILF_TOOL" "$ZORKS_ZILF_HOME/bin/$ZORKS_ZILF_TOOL"
  done
fi
chmod +x "$ZORKS_ZILF_HOME/bin/$ZORKS_ZILF_EXE"
printf 'Installed ZILF in %s\n' "$ZORKS_ZILF_HOME"
