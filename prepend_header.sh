#!/bin/sh

echo "# Apps Packages for Chakra, part of www.chakra-project.org" > /tmp/newfile
echo "# Maintainer: H W Tovetjärn (totte) <totte@tott.es>" >> /tmp/newfile
echo "" >> /tmp/newfile
cat ${1} >> /tmp/newfile
cp ${1} ${1}~
cp /tmp/newfile ${1}
