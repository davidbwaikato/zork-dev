#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/_llama_cpp_env.bash"

MODEL_URL="https://huggingface.co/${LLAMA_CPP_MODEL_REPOSITORY}/resolve/${LLAMA_CPP_MODEL_REVISION}/${LLAMA_CPP_MODEL_FILENAME}?download=true"
PARTIAL_PATH="${LLAMA_CPP_MODEL_PATH}.part"
VERIFIED_MARKER="${LLAMA_CPP_MODEL_PATH}.sha256-ok"

mkdir -p "${LLAMA_CPP_MODEL_DIR}"

model_is_verified() {
    [ -f "${LLAMA_CPP_MODEL_PATH}" ] || return 1
    [ "$(llama_cpp_file_size "${LLAMA_CPP_MODEL_PATH}")" = "${LLAMA_CPP_MODEL_SIZE}" ] || return 1
    [ -f "${VERIFIED_MARKER}" ] || return 1
    [ "$(tr -d '[:space:]' < "${VERIFIED_MARKER}")" = "${LLAMA_CPP_MODEL_SHA256}" ]
}

if model_is_verified ; then
    echo "Already downloaded and verified the llama.cpp command-interpreter model:"
    echo "  ${LLAMA_CPP_MODEL_PATH}"
    exit 0
fi

if [ -f "${LLAMA_CPP_MODEL_PATH}" ]; then
    EXISTING_SIZE="$(llama_cpp_file_size "${LLAMA_CPP_MODEL_PATH}")"
    if [ "${EXISTING_SIZE}" = "${LLAMA_CPP_MODEL_SIZE}" ]; then
        echo "Verifying the existing model download..."
        EXISTING_SHA256="$(llama_cpp_sha256_file "${LLAMA_CPP_MODEL_PATH}")"
        if [ "${EXISTING_SHA256}" = "${LLAMA_CPP_MODEL_SHA256}" ]; then
            printf '%s\n' "${LLAMA_CPP_MODEL_SHA256}" > "${VERIFIED_MARKER}"
            echo "Verified model: ${LLAMA_CPP_MODEL_PATH}"
            exit 0
        fi
    fi

    echo "Removing an incomplete or invalid model file before downloading it again." >&2
    rm -f -- "${LLAMA_CPP_MODEL_PATH}" "${VERIFIED_MARKER}"
fi

echo "----"
echo "Downloading the Qwen2.5 1.5B Instruct Q4_K_M command-interpreter model (approximately 1.12 GB):"
echo "  ${MODEL_URL}"
echo "----"
curl --location --fail --retry 3 --continue-at - \
    --output "${PARTIAL_PATH}" "${MODEL_URL}"

DOWNLOADED_SIZE="$(llama_cpp_file_size "${PARTIAL_PATH}")"
if [ "${DOWNLOADED_SIZE}" != "${LLAMA_CPP_MODEL_SIZE}" ]; then
    echo "Model size verification failed." >&2
    echo "Expected: ${LLAMA_CPP_MODEL_SIZE} bytes" >&2
    echo "Actual:   ${DOWNLOADED_SIZE} bytes" >&2
    exit 1
fi

echo "Verifying the downloaded model checksum..."
DOWNLOADED_SHA256="$(llama_cpp_sha256_file "${PARTIAL_PATH}")"
if [ "${DOWNLOADED_SHA256}" != "${LLAMA_CPP_MODEL_SHA256}" ]; then
    echo "Model checksum verification failed." >&2
    echo "Expected: ${LLAMA_CPP_MODEL_SHA256}" >&2
    echo "Actual:   ${DOWNLOADED_SHA256}" >&2
    exit 1
fi

mv -- "${PARTIAL_PATH}" "${LLAMA_CPP_MODEL_PATH}"
printf '%s\n' "${LLAMA_CPP_MODEL_SHA256}" > "${VERIFIED_MARKER}"

echo "Downloaded and verified the llama.cpp command-interpreter model:"
echo "  ${LLAMA_CPP_MODEL_PATH}"
