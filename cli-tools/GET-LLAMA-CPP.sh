#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "${SCRIPT_DIR}/../_set_core_envs.bash"
source "${SCRIPT_DIR}/_llama_cpp_env.bash"

case "${ARCH}" in
    x86_64|amd64) NORMALIZED_ARCH="x64" ;;
    aarch64|arm64) NORMALIZED_ARCH="arm64" ;;
    *)
        echo "Unsupported architecture for the prebuilt llama.cpp packages: ${ARCH}" >&2
        exit 1
        ;;
esac

if [[ "${OS}" == "MINGW"* ]] || [[ "${OS}" == "MSYS"* ]] || [[ "${OS}" == "CYGWIN"* ]]; then
    ARCHIVE_NAME="llama-${LLAMA_CPP_BUILD}-bin-win-cpu-${NORMALIZED_ARCH}.zip"
    ARCHIVE_KIND="zip"
    case "${NORMALIZED_ARCH}" in
        x64)   ARCHIVE_SHA256="fbbbc55e0eb2e1b07f9dcb9488616c98ed47d9003b90e15e7c8c7812c4307cd3" ;;
        arm64) ARCHIVE_SHA256="4b136692ab17009722e350d5bb8e5905f9af6bcd43d2897f0655186a9cc65db6" ;;
    esac
elif [[ "${OS}" == "Linux" ]]; then
    ARCHIVE_NAME="llama-${LLAMA_CPP_BUILD}-bin-ubuntu-${NORMALIZED_ARCH}.tar.gz"
    ARCHIVE_KIND="tar.gz"
    case "${NORMALIZED_ARCH}" in
        x64)   ARCHIVE_SHA256="f263a91280471b4c33c4999d7c76259c0f3a0a53a0b3e692b2c0b84380137a35" ;;
        arm64) ARCHIVE_SHA256="e7491dca79c9799fc3ae169675a79f5777d3027e31ffb08ae679e5e0a7ae3c97" ;;
    esac
elif [[ "${OS}" == "Darwin" ]]; then
    ARCHIVE_NAME="llama-${LLAMA_CPP_BUILD}-bin-macos-${NORMALIZED_ARCH}.tar.gz"
    ARCHIVE_KIND="tar.gz"
    case "${NORMALIZED_ARCH}" in
        x64)   ARCHIVE_SHA256="b7adecf7bd2cde577ddabee8357a72409165d8104f43b4acee9f1b98cc9c447a" ;;
        arm64) ARCHIVE_SHA256="ee3324327d621026ae80c24031670e65fa62a0b23a3a027dbe2f65f240affd30" ;;
    esac
else
    echo "Unsupported operating system for the prebuilt llama.cpp packages: ${OS}" >&2
    exit 1
fi

ARCHIVE_URL="https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_CPP_BUILD}/${ARCHIVE_NAME}"
ARCHIVE_PATH="${LLAMA_CPP_DOWNLOAD_DIR}/${ARCHIVE_NAME}"
PARTIAL_PATH="${ARCHIVE_PATH}.part"

mkdir -p "${LLAMA_CPP_DOWNLOAD_DIR}"

if [ -f "${LLAMA_CPP_SERVER_PATH}" ] ; then
    echo "Already installed llama.cpp ${LLAMA_CPP_BUILD}:"
    echo "  ${LLAMA_CPP_INSTALL_DIR}"
    "${LLAMA_CPP_SERVER_PATH}" --version
    exit 0
fi

if [ -e "${LLAMA_CPP_INSTALL_DIR}" ] ; then
    echo "The llama.cpp installation directory exists but does not contain the expected server:" >&2
    echo "  ${LLAMA_CPP_SERVER_PATH}" >&2
    echo "Move or remove '${LLAMA_CPP_INSTALL_DIR}' and run this script again." >&2
    exit 1
fi

if [ -f "${ARCHIVE_PATH}" ]; then
    ACTUAL_SHA256="$(llama_cpp_sha256_file "${ARCHIVE_PATH}")"
    if [ "${ACTUAL_SHA256}" != "${ARCHIVE_SHA256}" ]; then
        echo "Removing an invalid cached llama.cpp archive." >&2
        rm -f -- "${ARCHIVE_PATH}"
    fi
fi

if [ ! -f "${ARCHIVE_PATH}" ]; then
    echo "----"
    echo "Downloading llama.cpp ${LLAMA_CPP_BUILD}:"
    echo "  ${ARCHIVE_URL}"
    echo "----"
    curl --location --fail --retry 3 --continue-at - \
        --output "${PARTIAL_PATH}" "${ARCHIVE_URL}"
    mv -- "${PARTIAL_PATH}" "${ARCHIVE_PATH}"
fi

ACTUAL_SHA256="$(llama_cpp_sha256_file "${ARCHIVE_PATH}")"
if [ "${ACTUAL_SHA256}" != "${ARCHIVE_SHA256}" ]; then
    echo "llama.cpp archive checksum verification failed." >&2
    echo "Expected: ${ARCHIVE_SHA256}" >&2
    echo "Actual:   ${ACTUAL_SHA256}" >&2
    exit 1
fi

STAGING_DIR="$(mktemp -d "${SCRIPT_DIR}/.llama-cpp-install.XXXXXX")"
EXTRACT_DIR="${STAGING_DIR}/extracted"
INSTALL_IN_PROGRESS=0
mkdir -p "${EXTRACT_DIR}"
cleanup() {
    if [ "${INSTALL_IN_PROGRESS:-0}" -eq 1 ] && [ -d "${LLAMA_CPP_INSTALL_DIR}" ]; then
        rm -rf -- "${LLAMA_CPP_INSTALL_DIR}"
    fi
    if [ -n "${STAGING_DIR:-}" ] && [ -d "${STAGING_DIR}" ]; then
        rm -rf -- "${STAGING_DIR}"
    fi
}
trap cleanup EXIT

echo "Extracting ${ARCHIVE_NAME}..."
if [ "${ARCHIVE_KIND}" = "zip" ]; then
    unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_DIR}"
else
    tar --no-same-owner --strip-components=1 -xzf "${ARCHIVE_PATH}" -C "${EXTRACT_DIR}"
fi

STAGED_SERVER="$(find "${EXTRACT_DIR}" -maxdepth 2 -type f -name "$(basename "${LLAMA_CPP_SERVER_PATH}")" -print -quit)"
if [ -z "${STAGED_SERVER}" ] || [ ! -f "${STAGED_SERVER}" ]; then
    echo "The extracted package does not contain the expected executable:" >&2
    echo "  $(basename "${LLAMA_CPP_SERVER_PATH}")" >&2
    exit 1
fi

chmod +x "${STAGED_SERVER}" 2>/dev/null || true
PACKAGE_DIR="$(dirname "${STAGED_SERVER}")"

# Git Bash on Windows can reject renaming a populated extracted directory even
# when the source and destination are on the same drive. Copying the package
# contents into a freshly created destination is reliable on Windows and keeps
# the same behaviour on Linux and macOS. The EXIT trap removes a partial
# installation if the copy or subsequent validation fails.
mkdir -- "${LLAMA_CPP_INSTALL_DIR}"
INSTALL_IN_PROGRESS=1
cp -R -- "${PACKAGE_DIR}/." "${LLAMA_CPP_INSTALL_DIR}/"

if [ ! -f "${LLAMA_CPP_SERVER_PATH}" ]; then
    echo "The installed llama.cpp package does not contain the expected executable:" >&2
    echo "  ${LLAMA_CPP_SERVER_PATH}" >&2
    exit 1
fi

chmod +x "${LLAMA_CPP_SERVER_PATH}" 2>/dev/null || true
INSTALL_IN_PROGRESS=0

echo "Installed llama.cpp ${LLAMA_CPP_BUILD}:"
echo "  ${LLAMA_CPP_INSTALL_DIR}"
"${LLAMA_CPP_SERVER_PATH}" --version
