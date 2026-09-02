

STORED_CWD_CT="${PWD}"

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"

source ../_set_core_envs.bash
source ./_llama_cpp_env.bash


if [ -f "${LLAMA_CPP_SERVER_PATH}" ] ; then
    case ":${PATH}:" in
	*":${LLAMA_CPP_INSTALL_DIR}:"*) ;;
	*) export PATH="${LLAMA_CPP_INSTALL_DIR}:${PATH}" ;;
    esac
    export ZUI_LLAMA_CPP_SERVER="${LLAMA_CPP_SERVER_PATH}"
    echo "Updated PATH to include llama.cpp CLI tools"
else
    echo "Warning: Failed to find llama.cpp server at '${LLAMA_CPP_SERVER_PATH}'" >&2
    echo "         Run dev/cli-tools/GET-LLAMA-CPP.sh to install it." >&2
fi

if [ -f "${LLAMA_CPP_MODEL_PATH}" ] ; then
    export ZUI_LLAMA_CPP_MODEL="${LLAMA_CPP_MODEL_PATH}"
else
    echo "Warning: Failed to find the llama.cpp model at '${LLAMA_CPP_MODEL_PATH}'" >&2
    echo "         Run dev/cli-tools/GET-LLAMA-CPP-MODEL.sh to download it." >&2
fi

if [ -f "${LLAMA_CPP_SERVER_PATH}" ] && [ -f "${LLAMA_CPP_MODEL_PATH}" ] ; then
    export ZUI_COMMAND_INTERPRETATION="${ZUI_COMMAND_INTERPRETATION:-true}"
    export ZUI_LLM_CHAT_URL="${ZUI_LLM_CHAT_URL:-http://127.0.0.1:8080/v1/chat/completions}"
    export ZUI_LLM_MODEL="${ZUI_LLM_MODEL:-${LLAMA_CPP_MODEL_ALIAS}}"
    export ZUI_LLM_TIMEOUT_MS="${ZUI_LLM_TIMEOUT_MS:-30000}"
    echo "Configured local Zork command interpretation"
fi

if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then    

    if [ -f dfrotz-win64/dfrotz.exe ] ; then
	export PATH="${SCRIPT_DIR}/dfrotz-win64:$PATH"
	echo "Updated PATH to include dfrotz"
    else
	echo "Failed to find ${SCRIPT_DIR}/dfrotz-win64/dfrotz.exe"
    fi
else
    echo "!!!!"
    echo "! Currently no setup code included for Operating System: $OS"
    echo "!!!!"
fi


cd "${STORED_CWD_CT}"
