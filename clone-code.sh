#!/bin/sh
git clone https://github.com/HaxeFoundation/hashlink hashlink
pushd hashlink

# EDIT: 2023-11-08: 1.14/master branch introduces a breaking change on
# its ABI. With this change, bytecode compiled by haxe can't be executed
# by latest hashlink. It may produce error message like below:
#
#    /home/fuzhouch/projects/thirdparty/hashlink/src/module.c(574) :
#    FATAL ERROR : Invalid signature for function fmt@mp3_open :
#    PBi_Xfmt_mp3_ required but P_Xfmt_mp3_ found in hdll
#
# Let's wait until 1.14 is mature enough with haxe updated. 
git checkout 1.13
popd
