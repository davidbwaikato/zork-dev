#!/bin/bash
set -euo pipefail


cd prog-langs \
    && ./GET-ZILF-WIN64.sh \
    && ./GET-NODEJS-WIN64.sh \
    && cd ..


cd prog-langs \
    && ./CREATE-PYTHON-VENV.sh \
    && cd ..

./PIP-INSTALL-FOR-ZORK.sh


cd cli-tools \
    && ./GET-DFROTZ-WIN64.sh \
    && cd ..


















