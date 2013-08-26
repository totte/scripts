#!/bin/sh
# Note to self, run this first:
#   detox -nv /path/to/directory

find . -maxdepth 1 -type f -print0 | while read -r -d '' FILENAME
    do mv -v "$FILENAME" `echo $FILENAME | tr -s " " "_"`
done
