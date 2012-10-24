#!/bin/bash
# Replace spaces with underscores,
# delete {}(),\!' characters,
# set all letters to lower case,
# replace _-_ with -.

ls | while read -r FILE
do
    mv -v "$FILE" `echo $FILE | tr ' ' '_' | tr -d '[{}(),\!]' | tr -d "\'" | tr '[A-Z]' '[a-z]' | sed 's/_-_/-/g'`
done
