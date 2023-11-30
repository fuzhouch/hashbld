@echo off
git clone https://github.com/HaxeFoundation/hashlink hashlink
REM  
REM  Hashlink master branch must work with Heaps master. Using Hashlink
REM  from master branch and Heaps with Haxelib can causes ABI mangling
REM  error like below:
REM 
REM     /home/fuzhouch/projects/thirdparty/hashlink/src/module.c(574) :
REM     FATAL ERROR : Invalid signature for function fmt@mp3_open :
REM     PBi_Xfmt_mp3_ required but P_Xfmt_mp3_ found in hdll
REM 
echo ===============================================================
echo Hashlink code checked out. Please build with Xmake with steps below.
echo 
echo     xmake config -p windows -a x64 -m {debug or release}
echo     or
echo     xmake config -p {linux or macosx} -a x86_64 -m { debug or release}
echo     xmake build
echo     xmake install -o package64
echo ===============================================================
