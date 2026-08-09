#!/bin/bash
set -euo pipefail

source ../ACTIVATE-PYTHON.bash


echo "=== Installing Pytorch with GPU support if available ==="
source ./_PIP-INSTALL-PYTORCH.sh





