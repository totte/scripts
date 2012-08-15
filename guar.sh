#!/bin/sh -x
# guar: git update and rebase
set -o errexit
current=`git branch | awk '/\*/{print $2}'`
git checkout master
git pull origin master
git checkout ${current}
git rebase master
