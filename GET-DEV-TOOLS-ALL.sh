#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"

cd prog-langs \
    && ./GET-ZILF-WIN64.sh \
    && ./GET-NODEJS-WIN64.sh \
    && cd ..


cd prog-langs \
    && ./GET-VENV-PYTHON.sh \
    && ./PIP-INSTALL-PYTORCH.sh \
    && cd ..


cd prog-langs \
    && VENV_DIR="python-for-stableaudio" ./GET-VENV-PYTHON.sh \
    && VENV_DIR="python-for-stableaudio" ./PIP-INSTALL-STLABLEAUDIO.sh \
    && cd ..



cd cli-tools \
    && ./GET-DFROTZ-WIN64.sh \
    && ./GET-LLAMA-CPP.sh \
    && ./GET-LLAMA-CPP-MODEL.sh \
    && ./GET-COMFYUI.sh \
    && ./PIP-INSTALL-FOR-COMFYUI.sh \
    && ./DOWNLOAD-MODELS-FOR-COMFYUI.sh \
    && cd ..

















