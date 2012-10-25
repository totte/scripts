#!/bin/sh
# Move all files in cwd to msc/a-z

for i in {a..z}
do
    mv --backup ./$i* $HOME/msc/$i/
done
