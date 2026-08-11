#!/bin/bash
set -e

# Determine the absolute directory where this script resides (project root)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source env definition script relative to prog-langs/
source "${SCRIPT_DIR}/_set_core_envs.bash"

need_to_activate_venv=1

if [ ! -z "${VIRTUAL_ENV:-}" ] ; then
    if [ "${VIRTUAL_ENV##*/}" = "${VENV_DIR##*/}" ] ; then
        need_to_activate_venv=0
    else
        # Need to deactivate current venv before activating target venv
        deactivate
    fi
fi

if [ "$need_to_activate_venv" = "1" ] ; then

    FULL_VENV_DIR="${SCRIPT_DIR}/prog-langs/${VENV_DIR}"

    if [ -d "${FULL_VENV_DIR}" ] ; then

        # Determine activation script path based on OS
        if [[ "${OS:-}" == "MINGW"* ]] || [[ "${OS:-}" == "MSYS"* ]] || [[ "${OS:-}" == "CYGWIN"* ]]; then
            ACTIVATE_SCRIPT="${FULL_VENV_DIR}/Scripts/activate"
        else
            ACTIVATE_SCRIPT="${FULL_VENV_DIR}/bin/activate"
        fi

        echo "[+] Sourcing virtual environment: ${ACTIVATE_SCRIPT}"
        source "${ACTIVATE_SCRIPT}"


	# Fix the double parentheses string prompt caused by upstream bug
	# in Python 3.12 (specifically CPython issue #132361).
	PS1="${PS1//\(\(${VENV_DIR}\) \)/(${VENV_DIR})}"
	
    else
        echo "====" >&2
        echo "Warning: Failed to find: '${FULL_VENV_DIR}/'" >&2
        echo "Have you installed the Python venv for Zorks Illustrated with ./GET-VENV-PYTHON?" >&2
        echo "====" >&2
    fi
else
    echo "Python virtual environment already active:"
    echo "  ${VIRTUAL_ENV}"
fi

set +e
