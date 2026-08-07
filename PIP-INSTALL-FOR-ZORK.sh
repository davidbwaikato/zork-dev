#!/bin/bash
set -euo pipefail


if [ -d prog-langs/python-for-zork ] ; then
    echo "Activating 'python-for-zork'"
    source ./prog-langs/python-for-zork/Scripts/activate
else
    echo "====" >&2
    echo "Warning: Failed to find:'python-for-zork/'" >&2
    echo "Have you installed the Python venv for Zorks Illustrated?" >&2
    echo "====" >&2
fi


# Upgrade pip if needed to prevent potential warning messages about it
# being out of date

python -m pip install --upgrade pip


#echo "Installing 'dotenv' for API Keys and Environment Variable settings'"
#pip install python-dotenv
#
#echo "Installing youtube downloader package: 'yt-dlp'"
#pip install yt-dlp yt-dlp-ejs
#
#echo "Installing 'pillow' for image resizing"
#pip install pillow
#
#echo "Installing 'pypdfium2' for PDF to Image conversion"
#pip install pypdfium2
#
#echo "Installing playwright for browser automation: 'playwright'"
#pip install playwright
#echo "Installing chromium for use with playwright"
#playwright install chromium





