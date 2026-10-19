#!/bin/bash
set -euo pipefail

OS="$(uname -s)"

source ../ACTIVATE-PYTHON.bash

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"


had_error=0

# Install ComfyUI Dependencies
echo "=== Installing requirements for CompfyUI ==="

if [ -f "ComfyUI/requirements.txt" ] ; then

    if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
	echo "**** Detected Windows OS, switching to comfyUI_exact_requirements_win64.txt"
	echo "!!!! Assumes cu130 drivers for CUDA !!!!" 
	COMFYUI_CMD="pip install -r comfyUI_exact_requirements_win64.txt"
    else	
	COMFYUI_CMD="pip install -r ComfyUI/requirements.txt"
    fi
    
    echo "  [+] Executing: $COMFYUI_CMD"
    $COMFYUI_CMD

    if [ $? != 0 ] ; then
	had_error=1
    fi
else
    echo "Error: Failed to find ComfyUI/requirements.txt" 1>&2
    had_error=1
fi


if [ $had_error = 0 ] ; then

    if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
	echo "**** Detected Windows OS, skipping explicit pip instal shaders"
	echo "!!!! => Should already be installed from comfyui_exact_requirements_win64.txt"
    else
	echo ""
	echo "=== Installing Shader support for ComfyUI ==="
	pip install PyOpenGL PyOpenGL-accelerate glfw
	
	if [ $? != 0 ] ; then
	    had_error=1
	fi
    fi
else
    echo "Warning: Did not install Shader support for ComfyUI due to earlier error"    
fi

if [ $had_error = 0 ] ; then
    echo "=== Installing Hugging Face CLI with HF Transfer support for faster downloads ==="
    pip install huggingface_hub hf-xet 

    if [ $? != 0 ] ; then
	had_error=1
    fi
fi

if [ $had_error = 0 ] ; then
    echo "===="
    echo "Now run:"
    echo "  ./DOWNLOAD-MODELS-FOR-COMFYUI.sh"
    echo "===="
else
    had_error=1
fi

exit $had_error
