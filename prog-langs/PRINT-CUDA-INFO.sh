#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/ACTIVATE-PYTHON.bash"
python -c 'import torch; print("PyTorch:",torch.__version__); print("CUDA available:",torch.cuda.is_available()); print("Device:",torch.cuda.get_device_name(0) if torch.cuda.is_available() else "CPU / MPS")'
