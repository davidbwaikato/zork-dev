

if [ -f dfrotz/dfrotz.exe ] ; then
    export PATH="$PWD/dfrotz:$PATH"
    echo "Updated PATH to include dfrotz"
else
    echo "Failed to find $PWD/dfrotz/dfrotz.exe"
fi	

