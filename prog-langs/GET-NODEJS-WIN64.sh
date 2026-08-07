#!/bin/bash

pl_version=v24
pl_full_version=v24.18.0


proglang_binary_dist="node-${pl_full_version}-win-x64"
proglang_install_dir="node-${pl_version}"


proglang_zipfile="${proglang_binary_dist}.zip"

# For example:
#   https://nodejs.org/dist/v24.18.0/node-v24.18.0-win-x64.zip

proglang_download_url=https://nodejs.org/dist/${pl_full_version}/${proglang_zipfile}


if [ ! -f "$proglang_zipfile" ] ; then
    echo "----"
    echo "Downloading: $proglang_download_url"
    echo "----"
    
    wget --help >/dev/null 2>&1
    if [ $? = 0 ] ; then
	wget --no-check-certificate -v --output-file="$proglang_zipfile" "$proglang_download_url"
    else
	curl --output="$proglang_zipfile" "$proglang_download_url"
    fi
else
    echo "Already downloaded '$proglang_zipfile'"
fi


if [ ! -d $proglang_install_dir ] ; then

    # Work with Windows 'tar', which can handle zip format
    tar_full_path='C:\Windows\System32\tar.exe'

    cygpath --help >/dev/null 2>&1
    if [ $? = 0 ] ; then
	tar_full_path=`cygpath $tar_full_path`
    fi
    $tar_full_path xvzf $proglang_zipfile

    # Sometimes mv command gets 'permission denied' on Windows
    # => likely to be file-lock related
    # => adding small sleep to give OS file-system tie to settle down after unzipping
    sleep 2

    /bin/mv -v $proglang_binary_dist $proglang_install_dir
else
    echo "Already unpacked '$proglang_binary_dist' as '$proglang_install_dir'"
fi

