#!/bin/bash

# Assumes you already have dotnet on your PATH (e.g. 'apt install dotnet')

if [ ! -d zilf ] ; then
    tar xvzf zilf.tar.gz 
fi

cd zilf && \
    dotnet build Zilf.sln -c Release
cd ..

echo ""
echo "!!!!!!!!!!!!!!!!!!!"
echo "! To compile Zork, you currently need to manually update your PATH to include zilf binaries"
echo "!!!!!!!!!!!!!!!!!!!"
echo ""
