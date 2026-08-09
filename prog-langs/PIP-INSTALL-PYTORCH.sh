#!/bin/bash
set -e

# Script to determine if PyTorch with GPU support is available
# If it is, then it installs the highest compatible version

#
# It also sets the variable $_PYTORCH_INDEX_URL
# => source this file if you want to have this variable
#    to use in other pip install commands
#
_PYTORCH_INDEX_URL=

echo "= Auto-Detecting System & Hardware for PyTorch ="

# 1. Check Operating System
OS="$(uname -s)"
ARCH="$(uname -m)"

PYTORCH_CMD=""

if [[ "$OS" == "Darwin" ]]; then
    echo "  [+] macOS detected ($ARCH). Using Metal (MPS) default PyTorch builds."
    PYTORCH_CMD="pip install torch torchvision torchaudio"

elif command -v nvidia-smi &> /dev/null; then
    echo "  [+] NVIDIA GPU detected via nvidia-smi."

    # Extract CUDA version from nvidia-smi output
    CUDA_VER=$(nvidia-smi | sed -n 's/.*CUDA Version: \([0-9]*\.[0-9]*\).*/\1/p' | head -n 1)

    if [[ -z "$CUDA_VER" ]]; then
        echo "  [!] Could not parse CUDA version string. Defaulting to CUDA 12.1 index."
        _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu121"
    else
        echo "  [+] Highest supported CUDA Version: $CUDA_VER"

        # Split major and minor versions
        CUDA_MAJOR=$(echo "$CUDA_VER" | cut -d. -f1)
        CUDA_MINOR=$(echo "$CUDA_VER" | cut -d. -f2)

        # Cascading checks from highest available PyTorch index to lowest
        if [[ "$CUDA_MAJOR" -gt 13 ]] || { [[ "$CUDA_MAJOR" -eq 13 ]] && [[ "$CUDA_MINOR" -ge 2 ]]; }; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu132"
        elif [[ "$CUDA_MAJOR" -eq 13 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu130"
        elif [[ "$CUDA_MAJOR" -eq 12 ]] && [[ "$CUDA_MINOR" -ge 8 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu128"
        elif [[ "$CUDA_MAJOR" -eq 12 ]] && [[ "$CUDA_MINOR" -ge 6 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu126"
        elif [[ "$CUDA_MAJOR" -eq 12 ]] && [[ "$CUDA_MINOR" -ge 4 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu124"
        elif [[ "$CUDA_MAJOR" -eq 12 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu121"
        elif [[ "$CUDA_MAJOR" -eq 11 ]] && [[ "$CUDA_MINOR" -ge 8 ]]; then
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu118"
        else
            echo "  [!] CUDA version is below 11.8 or unrecognized. Defaulting to CUDA 12.1."
            _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu121"
        fi
    fi

    PYTORCH_CMD="pip install torch torchvision torchaudio --index-url $_PYTORCH_INDEX_URL"

else
    echo "  [!] No NVIDIA GPU or driver found. Falling back to CPU-only PyTorch."
    _PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cpu"
    PYTORCH_CMD="pip install torch torchvision torchaudio --index-url $_PYTORCH_INDEX_URL"
fi

# 2. Execute PyTorch Installation

echo "===="
source ../ACTIVATE-PYTHON.bash
echo "===="

echo "  [+] Executing: $PYTORCH_CMD"
$PYTORCH_CMD
