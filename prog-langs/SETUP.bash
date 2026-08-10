
STORED_CWD="${PWD}"

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"

source _python_envs.bash


if [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
    
    if [ -d zilf-win64 ] ; then
	export PATH="$PWD/zilf-win64/bin:$PATH"
	echo "Updated PATH to include Zilf CLI tools"
    else
	echo "Warning: Failed to find Zilf CLI tools" >&2
    fi
    
    
    #if [ -d "${VENV_DIR} ] ; then
#	echo "  Activating 'python-for-zork'"
#	source ./python-for-zork/Scripts/activate
    #else
#	echo "====" >&2
#	echo "Warning: Failed to find:'${VENV_DIR}/'" >&2
#	echo "Have you installed the Python venv for Zorks Illustrated?" >&2
#	echo "====" >&2
#    fi
    
    if [ -d node-v24 ] ; then
	
	cd node-v24  \
	    && export PATH="$PWD:$PATH" \
	    && cd .. 
	echo "  Added NodeJS (v24) to PATH"
    else
	echo "====" >&2
	echo "Warning: Failed to find:node-v24'" >&2
	echo "====" >&2
    fi
    
    echo ""
elif [[ "$OS" == "Darwin" ]]; then
    echo ""
    echo "!!!! No current setup code implemented for Mac"
    echo "!!!! Is it possible to install 'dfrotz' using brew?"
    echo "!!!! If needing to recompile ZIL source, is it possible to install 'dotnet' using brew?"
    echo ""
else
    ## e.g., Linux
    if [ -d zilf-source ] ; then
	export PATH="${SCRIPT_DIR}/zilf-source/bin/Release/net10.0:$PATH"
	echo "Updated PATH to include 'zilf' binary"
    fi
    
    if [ -d node-v24.14.1-linux-x64 ] ; then
	export PATH="${SCRIPT_DIR}/node-v24.14.1-linux-x64/bin:$PATH"
	export NODE_PATH="${SCRIPT_DIR}/node-v24.14.1-linux-x64/lib/node_modules"
	echo "Updated PATH (and set NODE_PATH) to include NodeJS"
    fi
fi

cd "{$STORED_CWD}"
