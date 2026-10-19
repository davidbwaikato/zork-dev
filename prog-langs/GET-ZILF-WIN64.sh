#!/bin/bash


if [ ! -f zilf-1.9.0-win-x64.zip ] ; then
    curl -L --output=zilf-1.9.0-win-x64.zip https://github.com/taradinoc/zilf/releases/download/1.9/zilf-1.9.0-win-x64.zip        
else
    echo "Already downloaded Windows binary zilf-1.9.0-win-x64.zip"
fi

if [ ! -f zilf-win64/bin/zilf.exe ] ; then
    unzip -d zilf-win64 zilf-1.9.0-win-x64.zip
else
    echo "Already unzipped as zilf-win64/"
fi

