#!/bin/bash
set -e

echo "===="
source ../ACTIVATE-PYTHON.bash
echo "===="

##./PIP-INSTALL-PYTORCH.sh

python -m pip install --upgrade pip setuptools wheel

python -m pip install \
  torch==2.7.1 \
  torchaudio==2.7.1 \
  --index-url https://download.pytorch.org/whl/cu128

# Getting the following istalled correctly on Windows is reported to be quite difficult
# It's not needed if using the small-sfx model, so skipping for now
###python -m pip install flash-attn  

python -m pip install \
  "stable-audio-3 @ git+https://github.com/Stability-AI/stable-audio-3.git"


python -m pip install imageio-ffmpeg

hf auth login


echo ""
echo "===="
echo "To access the Stable Audio 3 model, accept the terms and conditions for the gated model at:"
echo "  https://huggingface.co/stabilityai/stable-audio-3-small-sfx"
echo "  https://huggingface.co/stabilityai/stable-audio-3-medium"

echo ""
echo "Note: It's possible that by accepting the terms to one of the models, acceess is then granted"
echo "      to their other models"

# The following variants don't (at the time of writing) appear to be gated
#echo "  https://huggingface.co/stabilityai/stable-audio-3-small-sfx-base"
#echo "  https://huggingface.co/stabilityai/stable-audio-3-medium-base"


# The following autoencoders, which get used in the pipeline, are already public
#SAME-S
#SAME-L

echo "===="
echo ""

