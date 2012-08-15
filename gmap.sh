#!/bin/sh -x
# gmap: git merge and push
set -o errexit
current=`git branch | awk '/\*/{print $2}'`
git checkout master
git merge ${current}
git push origin master
echo "Delete branch $current?"
select yn in "Yes" "No"; do
	case $yn in
		Yes )		echo "Deleting branch $current.";
					git branch -d ${current};
					exit 1;;
		No )		echo "Leaving branch $current as it is.";
					exit 1;;
	esac
done
