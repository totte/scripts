#!/bin/sh
# Move all files in cwd to music/a-z

for i in {a..z}
do
    mv --backup ./$i* $HOME/music/$i/
done
