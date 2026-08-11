

STORED_CWD_CT="${PWD}"

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"

source ../_set_core_envs.bash

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

