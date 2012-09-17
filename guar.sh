#!/bin/sh -x
# guar: git update and rebase

die ()
{
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided"

current=`git branch | awk '/\*/{print $2}'`
git checkout $1
git pull origin $1
git checkout ${current}
git rebase $1
