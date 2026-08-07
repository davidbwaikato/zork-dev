

if [ -d zilf-win64 ] ; then
    export PATH="$PWD/zilf-win64/bin:$PATH"
    echo "Updated PATH to include Zilf CLI tools"
else
    echo "Warning: Failed to find Zilf CLI tools" >&2
fi


if [ -d python-for-zork ] ; then
    echo "  Activating 'python-for-zork'"
    source ./python-for-zork/Scripts/activate
else
    echo "====" >&2
    echo "Warning: Failed to find:'python-for-zork/'" >&2
    echo "Have you installed the Python venv for NZUT?" >&2
    echo "====" >&2
fi

if [ -d node-v24 ] ; then

    cd node-v24  \
	&& export PATH="$PWD:$PATH" \
	&& cd ../.. 
    echo "  Added NodeJS (v24) to PATH"
else
    echo "====" >&2
    echo "Warning: Failed to find:node-v24'" >&2
    echo "====" >&2
fi

echo ""


#if [ -d node-v24.18.0-win-x64 ] ; then
#    export PATH="$PWD/node-v24.18.0-win-x64:$PATH"
#    echo "Updated PATH to include node-v24"
#else
#    echo "Warning: Failed to find NodeJS" >&2
#fi



