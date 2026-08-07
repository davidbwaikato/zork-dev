

echo "++++"
echo "Setting up dev tools used by prepare-content/ scripts"
echo "++++"

if [ -d prog-langs/python-for-zork ] ; then
    echo "  Activating 'python-for-zork'"
    source ./prog-langs/python-for-zork/Scripts/activate
else
    echo "====" >&2
    echo "Warning: Failed to find:'python-for-zork/'" >&2
    echo "Have you installed the Python venv for Zorks Illustrated?" >&2
    echo "====" >&2
fi

cd prog-langs && source ./SETUP-WINDOWS.bash && cd ..

cd cli-tools && source ./SETUP-WINDOWS.bash && cd ..


echo ""
