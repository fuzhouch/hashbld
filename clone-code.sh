#!/bin/sh
git clone https://github.com/HaxeFoundation/hashlink hashlink
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
echo     xmake config -p <windows|linux|macosx> -a x64 -m <debug|release>
echo     xmake build
echo     xmake install -o package64
echo ===============================================================
