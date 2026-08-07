

if [ -f dfrotz-win64/dfrotz.exe ] ; then
    export PATH="$PWD/dfrotz-win64:$PATH"
    echo "Updated PATH to include dfrotz"
else
    echo "Failed to find $PWD/dfrotz-win64/dfrotz.exe"
fi	

