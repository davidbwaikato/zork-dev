#!/bin/bash
set -euo pipefail


source ../ACTIVATE-PYTHON.bash

    
had_error=0

# Install ComfyUI Dependencies
echo "=== Installing requirements for CompfyUI ==="

if [ -f "ComfyUI/requirements.txt" ] ; then

    COMFYUI_CMD="pip install -r ComfyUI/requirements.txt"

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
    echo ""
    echo "=== Installing Shader support for ComfyUI ==="
    pip install PyOpenGL PyOpenGL-accelerate glfw
else
    echo "Warning: Did not install Shader support for ComfyUI due to earlier error"    
fi


exit $had_error
