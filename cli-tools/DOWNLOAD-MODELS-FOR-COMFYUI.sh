#!/bin/bash
set -euo pipefail

source ../ACTIVATE-PYTHON.bash

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -z "${HF_TOKEN:-}" ] ; then
    echo "===="
    echo "** Consider setting HF_TOKEN environment variable to make downloading models from Hugging Face faster"
    echo "===="
    sleep 5
fi

export HF_XET_HIGH_PERFORMANCE=1

cd "${SCRIPT_DIR}"

CLI_TOOLS_HOME="${SCRIPT_DIR}"
COMFYUI_MODELS_DIR="./ComfyUI-Models"


# -------------------------------------------------------------------
# 1. Qwen Text Encoder
# -------------------------------------------------------------------
qwen_textencoder_model="qwen_3_4b.safetensors"
qwen_textencoder_filename="${COMFYUI_MODELS_DIR}/TextEncoders/$qwen_textencoder_model"

echo "----"
if [ ! -f "$qwen_textencoder_filename" ] ; then
    echo "Downloading $qwen_textencoder_model to $qwen_textencoder_filename..."
    mkdir -p "${COMFYUI_MODELS_DIR}/TextEncoders"

    hf download Comfy-Org/z_image_turbo \
        "split_files/text_encoders/${qwen_textencoder_model}" \
        --local-dir "${COMFYUI_MODELS_DIR}/TextEncoders"

    # Flatten subdirectories
    mv "${COMFYUI_MODELS_DIR}/TextEncoders/split_files/text_encoders/${qwen_textencoder_model}" "$qwen_textencoder_filename"
    rm -rf "${COMFYUI_MODELS_DIR}/TextEncoders/split_files"
else
    echo "Skipping => Already downloaded $qwen_textencoder_filename"
fi
echo "----"


# -------------------------------------------------------------------
# 2. Flux Diffusion Model
# -------------------------------------------------------------------
flux_diffusion_model="flux-2-klein-4b-fp8.safetensors"
flux_diffusion_filename="${COMFYUI_MODELS_DIR}/DiffusionModels/${flux_diffusion_model}"

echo "----"
if [ ! -f "$flux_diffusion_filename" ] ; then
    echo "Downloading $flux_diffusion_model to $flux_diffusion_filename..."
    mkdir -p "${COMFYUI_MODELS_DIR}/DiffusionModels"

    # File is in repo root, so no directory cleanup is required
    hf download black-forest-labs/FLUX.2-klein-4b-fp8 \
        "${flux_diffusion_model}" \
        --local-dir "${COMFYUI_MODELS_DIR}/DiffusionModels"
else
    echo "Skipping => Already downloaded $flux_diffusion_filename"
fi
echo "----"


# -------------------------------------------------------------------
# 3. Flux VAE Model
# -------------------------------------------------------------------
flux_vae_model="flux2-vae.safetensors"
flux_vae_filename="${COMFYUI_MODELS_DIR}/VAE/$flux_vae_model"

echo "----"
if [ ! -f "$flux_vae_filename" ] ; then
    echo "Downloading $flux_vae_model to $flux_vae_filename..."
    mkdir -p "${COMFYUI_MODELS_DIR}/VAE"

    hf download Comfy-Org/flux2-dev \
        "split_files/vae/${flux_vae_model}" \
        --local-dir "${COMFYUI_MODELS_DIR}/VAE"

    # Flatten subdirectories
    mv "${COMFYUI_MODELS_DIR}/VAE/split_files/vae/${flux_vae_model}" "$flux_vae_filename"
    rm -rf "${COMFYUI_MODELS_DIR}/VAE/split_files"
else
    echo "Skipping => Already downloaded $flux_vae_filename"
fi
echo "----"


# -------------------------------------------------------------------
# 4. Generate Extra Model Paths Config
# -------------------------------------------------------------------
echo ""
echo "----"
echo "Generating ${COMFYUI_MODELS_DIR}/extra_model_paths.yaml"
echo "----"
echo ""

OS="$(uname -s)"
if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
    
    # Convert POSIX path (/c/...) to Windows path format (C:/...)
    CLI_TOOLS_HOME="$(cygpath -m "${CLI_TOOLS_HOME}")"
fi


cat "${COMFYUI_MODELS_DIR}/extra_model_paths.yaml.in" \
    | sed "s#@CLI_TOOLS_HOME@#${CLI_TOOLS_HOME}#g" \
	  > "${COMFYUI_MODELS_DIR}/extra_model_paths.yaml"



