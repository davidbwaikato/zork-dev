#!/bin/bash


if [ ! -f ComfyUI-0.30.2.tar.gz ] ; then
    curl -L --output=ComfyUI-0.30.2.tar.gz "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v0.30.2.tar.gz"

else
    echo "Already downloaded ComfyUI-0.30.2.tar.gz"
fi

if [ ! -d ComfyUI ] ; then
    tar xvzf ComfyUI-0.30.2.tar.gz && mv ComfyUI-0.30.2 ComfyUI
    
else
    echo "Already untarred ComfyUI"
fi


echo "===="
echo "No run:"
echo "  ./PIP-INSTALL-FOR-COMFYUI.sh"
echo "===="

