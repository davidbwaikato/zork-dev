#!/bin/bash

comfyui_version=0.22.0

if [ ! -f ComfyUI-$comfyui_version.tar.gz ] ; then
    curl -L --output=ComfyUI-${comfyui_version}.tar.gz "https://github.com/Comfy-Org/ComfyUI/archive/refs/tags/v${comfyui_version}.tar.gz"
else
    echo "Already downloaded ComfyUI-${comfyui_version}.tar.gz"
fi


if [ ! -d ComfyUI ] ; then
    tar xvzf ComfyUI-${comfyui_version}.tar.gz && mv ComfyUI-${comfyui_version} ComfyUI
    
else
    echo "Already untarred ComfyUI"
fi


echo "===="
echo "Now run:"
echo "  ./PIP-INSTALL-FOR-COMFYUI.sh"
echo "===="

