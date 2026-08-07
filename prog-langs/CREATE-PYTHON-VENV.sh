#!/bin/bash


if [ ! -d python-for-nzut ] ; then
    echo "----"
    echo "Creating 'python-for-nzut/'"
    echo "----"
    python -m venv python-for-nzut
else
    echo "----"
    echo "Python venv 'python-for-nzut/' already exists"
    echo "----"
fi





