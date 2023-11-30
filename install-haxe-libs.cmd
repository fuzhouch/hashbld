@echo off
echo ===============================================================
echo IMPORTANT: The script should be executed after building hashlink.
echo If it's not done, the script can run but libraries can't work.
echo ===============================================================
REM  We use the .hx file in hashlink code path to setup haxelib.
REM  
REM  NOTE
REM  Let's always stick to Heaps.io from Github. Based on the
REM  [Unofficial Heaps FAQ)(https://gist.github.com/Yanrishatum/ae3725a9e2b45e0766c065e573ed1f24),
REM  The Haxelib version produces a lot of warnings due to out-dated
REM  syntax. What is worse. The bytecode compiled by Hashlink master branch
REM  can cause name signature error when working with Heaps Haxelib version
REM  (1.10.0).
REM 
REM  Though I personall hold a concern that using Github version may make
REM  my game logic unreplicable, it seems it's just the practice of the
REM  community. If you worry about it, try to replace the branch name with
REM  a commit hash ID.
REM 
REM      haxelib git heaps https://github.com/HeapsIO/heaps.git 6ccc6ad
REM 
haxelib dev hlsdl hashlink/libs/sdl/
haxelib dev hlopenal hashlink/libs/openal/
haxelib dev hashlink hashlink/other/haxelib/
haxelib git heaps https://github.com/HeapsIO/heaps.git master
