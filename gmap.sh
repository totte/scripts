#!/bin/sh -x
# gmap: git merge and push

die ()
{
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "1 argument required, $# provided"

current=`git branch | awk '/\*/{print $2}'`
git checkout $1
git merge ${current}
git push origin $1
echo "Delete branch $current?"
select yn in "Yes" "No"; do
    case $yn in
        Yes )echo "Deleting branch $current.";
            git branch -d ${current};
            exit 1;;
        No )echo "Leaving branch $current as it is.";
            exit 1;;
    esac
done
