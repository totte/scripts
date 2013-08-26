#!/bin/sh

# Needs an if [ -f ${newname} ] then add number

filename="$1"
echo $filename
newname="$currentname.backup"

while [ -f $newname ]
do
    n=$(($n++));
    newname="$newname.$n"
done

echo $newname

#cp -v $1 ${1}.backup
