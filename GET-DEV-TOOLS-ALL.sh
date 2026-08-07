#!/bin/bash
set -euo pipefail


cd prog-langs \
    && ./GET-NODEJS-WIN64.sh \
    && cd ..


cd prog-langs \
    && ./CREATE-PYTHON-VENV.sh \
    && cd ..

./PIP-INSTALL-FOR-NZUT.sh


cd cli-tools \
    && ./GET-DFROTZ-WIN64.sh \
    && cd ..


















