#!/bin/sh

echo ===============================================================
echo IMPORTANT: The script should be executed after building hashlink.
echo If it's not done, the script can run but libraries do not work.
echo ===============================================================
# We use the .hx file in hashlink code path to setup haxelib.
# 
# NOTE
# Let's always stick to Heaps.io from Github. Based on the
# [Unofficial Heaps FAQ)(https://gist.github.com/Yanrishatum/ae3725a9e2b45e0766c065e573ed1f24),
# The Haxelib version produces a lot of warnings due to out-dated
# syntax. What is worse. The bytecode compiled by Hashlink master branch
# can cause name signature error when working with Heaps Haxelib version
# (1.10.0).
#
# Though I personall hold a concern that using Github version may make
# my game logic unreplicable, it seems it's just the practice of the
# community. If you worry about it, try to replace the branch name with
# a commit hash ID.
#
#     haxelib git heaps https://github.com/HeapsIO/heaps.git 6ccc6ad
#
haxelib dev hlsdl hashlink/libs/sdl/
haxelib dev hlopenal hashlink/libs/openal/
haxelib dev hashlink hashlink/other/haxelib/
haxelib --always git heaps https://github.com/HeapsIO/heaps.git master
