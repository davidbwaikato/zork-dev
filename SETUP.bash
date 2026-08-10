

echo "++++"
echo "Setting up dev tools used by prepare-content/ scripts"
echo "++++"

source ./ACTIVATE-PYTHON.bash

cd prog-langs && source ./SETUP.bash && cd ..

cd cli-tools && source ./SETUP.bash && cd ..


echo ""
