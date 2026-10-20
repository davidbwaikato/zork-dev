#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file: source %q\n' "$0" >&2; exit 1
fi
ZORKS_PL_SETUP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_PL_SETUP_DIR/ACTIVATE-NODEJS.bash" || return 1
ZORKS_PL_ZILF_HOME="$ZORKS_PL_SETUP_DIR/installed/zilf-$ZORKS_ZILF_VERSION-$ZORKS_DEV_OS-$ZORKS_DEV_ARCH"
# Include legacy installations when overlaying an existing Windows checkout.
for ZORKS_PL_ZILF_BIN in "$ZORKS_PL_ZILF_HOME/bin" "$ZORKS_PL_ZILF_HOME" "$ZORKS_PL_SETUP_DIR/zilf-win64/bin"; do
  if [[ -x "$ZORKS_PL_ZILF_BIN/zilf" || -x "$ZORKS_PL_ZILF_BIN/zilf.exe" ]]; then
    zorks_dev_prepend_path "$ZORKS_PL_ZILF_BIN"
    export ZILF_HOME="$(cd -- "$ZORKS_PL_ZILF_BIN/.." && pwd -P)"
    break
  fi
done
unset ZORKS_PL_SETUP_DIR ZORKS_PL_ZILF_HOME ZORKS_PL_ZILF_BIN
