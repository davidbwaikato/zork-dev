#!/bin/bash
set -euo pipefail


cd prog-langs \
    && ./GET-ZILF-WIN64.sh \
    && ./GET-NODEJS-WIN64.sh \
    && cd ..


cd prog-langs \
    && ./GET-VENV-PYTHON.sh \
    && ./PIP-INSTALL-PYTORCH.sh \
    && cd ..



cd cli-tools \
    && ./GET-DFROTZ-WIN64.sh \
    && ./GET-COMFYUI.sh \
    && ./PIP-INSTALL-FOR-COMFYUI.sh \
    && cd ..


















