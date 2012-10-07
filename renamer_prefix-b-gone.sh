#!/bin/sh

for i in [0-9]*;do mv "$i" "`echo $i|sed 's/^[0-9]*[^a-zA-Z]*//'`";done
