#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file rather than executing it:\n  source %q\n' "$0" >&2
  exit 1
fi

ZORKS_ACTIVATE_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ZORKS_DEV_ROOT="$(cd -- "$ZORKS_ACTIVATE_SCRIPT_DIR/.." && pwd -P)"

source "$ZORKS_DEV_ROOT/versions.env"
source "$ZORKS_ACTIVATE_SCRIPT_DIR/_common.bash"

zorks_dev_detect_host || return 1

ZORKS_DEV_NODE_DIST_NAME="node-v${ZORKS_NODE_VERSION}-${ZORKS_DEV_OS}-${ZORKS_DEV_ARCH}"
ZORKS_DEV_NODE_HOME="$ZORKS_ACTIVATE_SCRIPT_DIR/installed/$ZORKS_DEV_NODE_DIST_NAME"

if [[ "$ZORKS_DEV_OS" == "win" ]]; then
  ZORKS_DEV_NODE_BIN_DIR="$ZORKS_DEV_NODE_HOME"
  ZORKS_DEV_NODE_EXECUTABLE="$ZORKS_DEV_NODE_HOME/node.exe"
else
  ZORKS_DEV_NODE_BIN_DIR="$ZORKS_DEV_NODE_HOME/bin"
  ZORKS_DEV_NODE_EXECUTABLE="$ZORKS_DEV_NODE_BIN_DIR/node"
fi

if [[ ! -x "$ZORKS_DEV_NODE_EXECUTABLE" ]]; then
  printf 'Node.js is not installed in this dev submodule. Run:\n  %s/INSTALL-DEV-TOOLS-ALL.sh\n' \
    "$ZORKS_DEV_ROOT" >&2
  return 1
fi

zorks_dev_prepend_path "$ZORKS_DEV_NODE_BIN_DIR"

ZORKS_DEV_COREPACK_HOME="$ZORKS_ACTIVATE_SCRIPT_DIR/installed/corepack"
export ZORKS_DEV_ROOT
export ZORKS_DEV_NODE_HOME
export ZORKS_DEV_NODE_BIN_DIR
if [[ "$ZORKS_DEV_OS" == win ]] && command -v cygpath >/dev/null 2>&1; then
  export COREPACK_HOME="$(cygpath -m "$ZORKS_DEV_COREPACK_HOME")"
else
  export COREPACK_HOME="$ZORKS_DEV_COREPACK_HOME"
fi
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

hash -r
unset ZORKS_ACTIVATE_SCRIPT_DIR ZORKS_DEV_NODE_DIST_NAME
unset ZORKS_DEV_NODE_EXECUTABLE ZORKS_DEV_COREPACK_HOME
