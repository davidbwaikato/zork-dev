#!/bin/bash

# Shared, pinned llama.cpp and command-interpreter model configuration.
# This file is sourced by the provisioning scripts, cli-tools/SETUP.bash, and
# the parent repository's RUN-LLAMA-CPP-SERVER.sh.

LLAMA_CPP_CLI_TOOLS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

LLAMA_CPP_BUILD="b10516"
LLAMA_CPP_SOURCE_SHA256="bd13fa381488aa59ae4081aca24d368a956ad6e393c54931510a94d240590e33"
LLAMA_CPP_INSTALL_DIR="${LLAMA_CPP_CLI_TOOLS_DIR}/llama-cpp"
LLAMA_CPP_DOWNLOAD_DIR="${LLAMA_CPP_CLI_TOOLS_DIR}/llama-cpp-downloads"

LLAMA_CPP_MODEL_REPOSITORY="Qwen/Qwen2.5-1.5B-Instruct-GGUF"
LLAMA_CPP_MODEL_REVISION="dd26da440ef0330c47919d1ecae0966d24022222"
LLAMA_CPP_MODEL_FILENAME="qwen2.5-1.5b-instruct-q4_k_m.gguf"
LLAMA_CPP_MODEL_SIZE="1117320736"
LLAMA_CPP_MODEL_SHA256="6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e"
LLAMA_CPP_MODEL_DIR="${LLAMA_CPP_CLI_TOOLS_DIR}/llama-cpp-models"
LLAMA_CPP_MODEL_PATH="${LLAMA_CPP_MODEL_DIR}/${LLAMA_CPP_MODEL_FILENAME}"
LLAMA_CPP_MODEL_ALIAS="zork-command-interpreter"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) LLAMA_CPP_SERVER_PATH="${LLAMA_CPP_INSTALL_DIR}/llama-server.exe" ;;
    *)                    LLAMA_CPP_SERVER_PATH="${LLAMA_CPP_INSTALL_DIR}/llama-server" ;;
esac

llama_cpp_sha256_file() {
    local filename="$1"

    if command -v sha256sum >/dev/null 2>&1 ; then
        sha256sum "$filename" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1 ; then
        shasum -a 256 "$filename" | awk '{print $1}'
    else
        echo "Unable to verify '$filename': neither sha256sum nor shasum is available." >&2
        return 1
    fi
}

llama_cpp_file_size() {
    wc -c < "$1" | tr -d '[:space:]'
}
