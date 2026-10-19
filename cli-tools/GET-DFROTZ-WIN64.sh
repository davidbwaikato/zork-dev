#!/bin/bash


if [ ! -f dfrotz.zip ] ; then
    curl -L --output=dfrotz.zip "https://www.ifarchive.org/if-archive/infocom/interpreters/frotz/dfrotz.zip"
    
else
    echo "Already downloaded Windows binary dfrotz.zip"
fi

if [ ! -f dfrotz-win64/dfrotz.exe ] ; then
    unzip -d dfrotz-win64 dfrotz.zip
else
    echo "Already unzipped zip as dfrotz-win64/"
fi




