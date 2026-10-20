#!/usr/bin/env bash
set -euo pipefail
# Keep incompatible audio and illustration dependencies in separate venvs.
export VENV_DIR="${VENV_DIR:-python-for-stableaudio}"
ZORKS_AUDIO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$ZORKS_AUDIO_DIR/../versions.env"
source "$ZORKS_AUDIO_DIR/_common.bash"
zorks_dev_detect_host
ZORKS_AUDIO_PY="$(zorks_dev_python_executable "$(cd -- "$ZORKS_AUDIO_DIR/.." && pwd -P)")"
[[ -x "$ZORKS_AUDIO_PY" ]] || zorks_dev_die 'Install the Stable Audio Python environment first (see README.md)'
ZORKS_TORCH_PROFILE=stableaudio "$ZORKS_AUDIO_DIR/PIP-INSTALL-PYTORCH.sh"
"$ZORKS_AUDIO_PY" -m pip install --upgrade pip setuptools wheel
"$ZORKS_AUDIO_PY" -m pip install 'stable-audio-3 @ git+https://github.com/Stability-AI/stable-audio-3.git' imageio-ffmpeg
"$ZORKS_AUDIO_PY" -m pip check
printf 'Stable Audio installed. For gated weights, accept the model terms on Hugging Face and supply HF_TOKEN or run hf auth login separately.\n'
