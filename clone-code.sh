#!/bin/sh
echo ===============================================================
if [ -d "./hashlink" ]; then
    echo ./hashlink folder exists. Reset code and pull latest.
    cd hashlink
    git checkout -- .
    git pull
    cd ..
else
    echo Cloning code: https://github.com/HaxeFoundation/hashlink ...
    git clone https://github.com/HaxeFoundation/hashlink hashlink
    echo Cloning done.
fi
echo ===============================================================
echo Patching openal-static-build patch ...
cd hashlink
git apply ../patches/openal-static-build.patch
cd ..
echo Patching done.
echo ===============================================================
# 
# Hashlink master branch must work with Heaps master. Using Hashlink
# from master branch and Heaps with Haxelib can causes ABI mangling
# error like below:
#
#    /home/fuzhouch/projects/thirdparty/hashlink/src/module.c(574) :
#    FATAL ERROR : Invalid signature for function fmt@mp3_open :
#    PBi_Xfmt_mp3_ required but P_Xfmt_mp3_ found in hdll
#
echo ===============================================================
echo Hashlink code checked out. Please build with Xmake with steps below.
echo 
echo     xmake config -p windows -a x64 -m {debug or release}
echo     or
echo     xmake config -p {linux or macosx} -a x86_64 -m { debug or release}
echo     xmake build
echo     xmake install -o package64
echo ===============================================================
