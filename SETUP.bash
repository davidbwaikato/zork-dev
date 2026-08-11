
STORED_CWD_DEV="${PWD}"

# Determine the absolute directory where this script resides
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd "${SCRIPT_DIR}"


echo "++++"
echo "Setting up dev tools used by prepare-content/ scripts"
echo "++++"

source ./ACTIVATE-PYTHON.bash

cd prog-langs && source ./SETUP.bash && cd ..

cd cli-tools && source ./SETUP.bash && cd ..


echo ""


cd "${STORED_CWD_DEV}"
