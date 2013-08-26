#!/bin/sh

find . -name '*.png' -exec echo "<td><img src=\"{}\" /><p>{}</p></td>" >> files.txt \;