#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'Source this file: source %q\n' "$0" >&2; exit 1
fi
ZORKS_CT_SETUP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_CT_SETUP_DIR/../prog-langs/_common.bash" || return 1
zorks_dev_detect_host || return 1
source "$ZORKS_CT_SETUP_DIR/_llama_cpp_env.bash" || return 1
if [[ -x "$LLAMA_CPP_SERVER_PATH" ]]; then
  zorks_dev_prepend_path "$LLAMA_CPP_INSTALL_DIR"
  export ZUI_LLAMA_CPP_SERVER="$LLAMA_CPP_SERVER_PATH"
fi
if [[ -f "$LLAMA_CPP_MODEL_PATH" ]]; then
  export ZUI_LLAMA_CPP_MODEL="$LLAMA_CPP_MODEL_PATH"
fi
if [[ -x "$LLAMA_CPP_SERVER_PATH" && -f "$LLAMA_CPP_MODEL_PATH" ]]; then
  export ZUI_COMMAND_INTERPRETATION="${ZUI_COMMAND_INTERPRETATION:-true}"
  export ZUI_LLM_CHAT_URL="${ZUI_LLM_CHAT_URL:-http://127.0.0.1:8080/v1/chat/completions}"
  export ZUI_LLM_MODEL="${ZUI_LLM_MODEL:-$LLAMA_CPP_MODEL_ALIAS}"
  export ZUI_LLM_TIMEOUT_MS="${ZUI_LLM_TIMEOUT_MS:-30000}"
fi
if [[ "$ZORKS_DEV_OS" == win ]]; then
  ZORKS_CT_DFROTZ_DIR="$ZORKS_CT_SETUP_DIR/dfrotz-win64"
  ZORKS_CT_DFROTZ_NAME=dfrotz.exe
else
  ZORKS_CT_DFROTZ_DIR="$ZORKS_CT_SETUP_DIR/dfrotz-$ZORKS_DEV_OS-$ZORKS_DEV_ARCH"
  ZORKS_CT_DFROTZ_NAME=dfrotz
fi
if [[ -x "$ZORKS_CT_DFROTZ_DIR/$ZORKS_CT_DFROTZ_NAME" ]]; then
  zorks_dev_prepend_path "$ZORKS_CT_DFROTZ_DIR"
elif ! command -v dfrotz >/dev/null 2>&1; then
  printf 'dfrotz is not installed. Run %s/INSTALL-DFROTZ.sh\n' "$ZORKS_CT_SETUP_DIR" >&2
  return 1
fi
unset ZORKS_CT_SETUP_DIR ZORKS_CT_DFROTZ_DIR ZORKS_CT_DFROTZ_NAME
