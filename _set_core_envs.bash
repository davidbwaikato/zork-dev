
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ -z ${VENV_DIR:-} ] ; then
    VENV_DIR="python-for-zork"
fi



