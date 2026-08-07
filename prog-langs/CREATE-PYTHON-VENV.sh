#!/bin/bash


if [ ! -d python-for-zork ] ; then
    echo "----"
    echo "Creating 'python-for-zork/'"
    echo "----"
    python -m venv python-for-zork
else
    echo "----"
    echo "Python venv 'python-for-zork/' already exists"
    echo "----"
fi





