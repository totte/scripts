#!/bin/sh
export KATE_DIR=~/code/kate/build
export PATH=$KATE_DIR/bin:$PATH
export LD_LIBRARY_PATH=$KATE_DIR/lib:$LD_LIBRARY_PATH
export KDEDIR=$KATE_DIR
export KDEDIRS=$KDEDIR
export XDG_DATA_DIRS=$XDG_DATA_DIRS:$KATE_DIR/share
# update KDE's system configuration cache
kbuildsycoca4
# start app
$@
