#!/usr/bin/env bash
set -euo pipefail

ZORKS_NODE_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ZORKS_DEV_ROOT="$(cd -- "$ZORKS_NODE_SCRIPT_DIR/.." && pwd -P)"

source "$ZORKS_DEV_ROOT/versions.env"
source "$ZORKS_NODE_SCRIPT_DIR/_common.bash"

zorks_dev_detect_host

case "$ZORKS_DEV_OS" in
  linux|darwin)
    ZORKS_NODE_PLATFORM="$ZORKS_DEV_OS"
    ZORKS_NODE_ARCHIVE_EXTENSION="tar.xz"
    ;;
  win)
    ZORKS_NODE_PLATFORM="win"
    ZORKS_NODE_ARCHIVE_EXTENSION="zip"
    ;;
esac

ZORKS_NODE_DIST_NAME="node-v${ZORKS_NODE_VERSION}-${ZORKS_NODE_PLATFORM}-${ZORKS_DEV_ARCH}"
ZORKS_NODE_ARCHIVE_NAME="${ZORKS_NODE_DIST_NAME}.${ZORKS_NODE_ARCHIVE_EXTENSION}"
ZORKS_NODE_DOWNLOAD_DIR="$ZORKS_NODE_SCRIPT_DIR/downloads/nodejs"
ZORKS_NODE_INSTALL_PARENT="$ZORKS_NODE_SCRIPT_DIR/installed"
ZORKS_NODE_INSTALL_DIR="$ZORKS_NODE_INSTALL_PARENT/$ZORKS_NODE_DIST_NAME"
ZORKS_NODE_ARCHIVE_PATH="$ZORKS_NODE_DOWNLOAD_DIR/$ZORKS_NODE_ARCHIVE_NAME"
ZORKS_NODE_CHECKSUMS_PATH="$ZORKS_NODE_DOWNLOAD_DIR/SHASUMS256-v${ZORKS_NODE_VERSION}.txt"
ZORKS_NODE_BASE_URL="https://nodejs.org/dist/v${ZORKS_NODE_VERSION}"

if [[ "$ZORKS_DEV_OS" == "win" ]]; then
  ZORKS_NODE_EXECUTABLE="$ZORKS_NODE_INSTALL_DIR/node.exe"
else
  ZORKS_NODE_EXECUTABLE="$ZORKS_NODE_INSTALL_DIR/bin/node"
fi

if [[ -x "$ZORKS_NODE_EXECUTABLE" ]]; then
  ZORKS_NODE_ACTUAL_VERSION="$("$ZORKS_NODE_EXECUTABLE" --version)"
  if [[ "$ZORKS_NODE_ACTUAL_VERSION" == "v${ZORKS_NODE_VERSION}" ]]; then
    printf 'Node.js %s is already installed for %s-%s.\n' \
      "$ZORKS_NODE_ACTUAL_VERSION" "$ZORKS_DEV_OS" "$ZORKS_DEV_ARCH"
    exit 0
  fi
fi

mkdir -p "$ZORKS_NODE_DOWNLOAD_DIR" "$ZORKS_NODE_INSTALL_PARENT"

if [[ -d "$ZORKS_NODE_INSTALL_DIR" ]]; then
  ZORKS_NODE_BACKUP="${ZORKS_NODE_INSTALL_DIR}.incomplete.$(date +%Y%m%d%H%M%S)"
  printf 'Preserving incomplete installation as %s\n' "$ZORKS_NODE_BACKUP"
  zorks_dev_move_with_retry "$ZORKS_NODE_INSTALL_DIR" "$ZORKS_NODE_BACKUP"
fi

if [[ ! -f "$ZORKS_NODE_CHECKSUMS_PATH" ]]; then
  printf 'Downloading Node.js checksum manifest...\n'
  zorks_dev_download \
    "$ZORKS_NODE_BASE_URL/SHASUMS256.txt" \
    "$ZORKS_NODE_CHECKSUMS_PATH"
fi

if [[ ! -f "$ZORKS_NODE_ARCHIVE_PATH" ]]; then
  printf 'Downloading %s...\n' "$ZORKS_NODE_ARCHIVE_NAME"
  zorks_dev_download \
    "$ZORKS_NODE_BASE_URL/$ZORKS_NODE_ARCHIVE_NAME" \
    "$ZORKS_NODE_ARCHIVE_PATH"
fi

if ! zorks_dev_verify_node_archive \
  "$ZORKS_NODE_ARCHIVE_PATH" "$ZORKS_NODE_CHECKSUMS_PATH"; then
  printf 'Cached Node.js files failed verification; downloading them again.\n' >&2
  rm -f -- "$ZORKS_NODE_ARCHIVE_PATH" "$ZORKS_NODE_CHECKSUMS_PATH"
  zorks_dev_download \
    "$ZORKS_NODE_BASE_URL/SHASUMS256.txt" \
    "$ZORKS_NODE_CHECKSUMS_PATH"
  zorks_dev_download \
    "$ZORKS_NODE_BASE_URL/$ZORKS_NODE_ARCHIVE_NAME" \
    "$ZORKS_NODE_ARCHIVE_PATH"
  zorks_dev_verify_node_archive \
    "$ZORKS_NODE_ARCHIVE_PATH" "$ZORKS_NODE_CHECKSUMS_PATH"
fi

ZORKS_NODE_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/zorks-node.XXXXXX")"
cleanup_zorks_node_stage() {
  rm -rf -- "$ZORKS_NODE_STAGE"
}
trap cleanup_zorks_node_stage EXIT

printf 'Installing Node.js locally...\n'
zorks_dev_extract_archive "$ZORKS_NODE_ARCHIVE_PATH" "$ZORKS_NODE_STAGE"

ZORKS_NODE_EXTRACTED_DIR="$ZORKS_NODE_STAGE/$ZORKS_NODE_DIST_NAME"
[[ -d "$ZORKS_NODE_EXTRACTED_DIR" ]] || {
  zorks_dev_die "Expected extracted directory was not found: $ZORKS_NODE_EXTRACTED_DIR"
  exit 1
}

zorks_dev_move_with_retry "$ZORKS_NODE_EXTRACTED_DIR" "$ZORKS_NODE_INSTALL_DIR"

[[ -x "$ZORKS_NODE_EXECUTABLE" ]] || {
  zorks_dev_die "Node.js installation did not produce $ZORKS_NODE_EXECUTABLE"
  exit 1
}

printf 'Installed Node.js %s in %s\n' \
  "$("$ZORKS_NODE_EXECUTABLE" --version)" "$ZORKS_NODE_INSTALL_DIR"
