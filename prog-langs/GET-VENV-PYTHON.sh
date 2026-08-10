#!/bin/bash
set -e

# Unset conflicting global Python environment variables
unset PYTHONHOME
unset PYTHONPATH

# If looking to update sub-build of the current version of Python used
# (or set up a major version) then visit:
#
#   https://github.com/indygreg/python-build-standalone/releases/latest
#
# This will auto-redirect to the latest tagged version
#
# Then you can use Ctrl-F to search through to find the build you want

STANDALONE_VER="20260807" # Choose a stable release tag from indygreg releases

python_main_version=3.12
python_full_version=3.12.13

PYTHON_DIR="portable-python-$python_main_version"

source ../_set_core_envs.bash

# 1. Determine target filename and URL based on OS and Architecture
if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
    # Windows (x86_64) - Note: '-shared' is omitted in current indygreg builds
    OS_TAR_FILE="cpython-${python_full_version}+${STANDALONE_VER}-x86_64-pc-windows-msvc-install_only.tar.gz"
elif [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        # macOS Apple Silicon
        OS_TAR_FILE="cpython-${python_full_version}+${STANDALONE_VER}-aarch64-apple-darwin-install_only.tar.gz"
    else
        # macOS Intel
        OS_TAR_FILE="cpython-${python_full_version}+${STANDALONE_VER}-x86_64-apple-darwin-install_only.tar.gz"
    fi
else
    # Linux (x86_64)
    OS_TAR_FILE="cpython-${python_full_version}+${STANDALONE_VER}-x86_64-unknown-linux-gnu-install_only.tar.gz"
fi

URL_PREFIX="https://github.com/indygreg/python-build-standalone/releases/download/${STANDALONE_VER}"
URL="${URL_PREFIX}/${OS_TAR_FILE}"

# 2. Download the .tar.gz archive if not already present on disk
mkdir -p tar-downloads
if [ ! -f "tar-downloads/$OS_TAR_FILE" ]; then
    echo "[+] Downloading Portable Python $python_main_version archive (tar-downloads/$OS_TAR_FILE)..."
    curl -L "$URL" -o "tar-downloads/$OS_TAR_FILE"
else
    echo "[+] Archive 'tar-downloads/$OS_TAR_FILE' already exists locally. Skipping download."
fi

# 3. Extract the tar archive into PYTHON_DIR if not already extracted
if [ ! -d "$PYTHON_DIR" ]; then
    echo "[+] Extracting 'tar-downloads/$OS_TAR_FILE' into '$PYTHON_DIR'..."
    mkdir -p "$PYTHON_DIR"
    tar -xzf "tar-downloads/$OS_TAR_FILE" -C "$PYTHON_DIR" --strip-components=1
else
    echo "[+] Directory '$PYTHON_DIR' already exists. Skipping extraction."
fi

# 4. Locate the standalone Python binary
if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
    STANDALONE_PY="$(pwd)/$PYTHON_DIR/python.exe"
else
    STANDALONE_PY="$(pwd)/$PYTHON_DIR/bin/python3"
fi

# 5. Create Virtual Environment using the Standalone Python
# ($VENV_DIR set in ../_set_core_envs.bash)

if [ ! -d "$VENV_DIR" ]; then
    echo "[+] Creating virtual environment in '$VENV_DIR' using Portable Python $python_main_version..."
    "$STANDALONE_PY" -m venv "$VENV_DIR"
else
    echo "[+] Virtual environment '$VENV_DIR' already exists."
fi

source ../ACTIVATE-PYTHON.bash

# 6. Upgrade pip to avoid subsequent warnings about there being a new version available
echo "[+] Upgrading pip..."
python -m pip install --upgrade pip

echo ""
echo "----"
echo "Now run:"
echo "   ./PIP-INSTALL-PYTORCH.sh"
echo "----"
echo ""


