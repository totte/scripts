#!/bin/sh
# gtask: start and finish new feature, hotfix or release branches

usage()
{
    echo "Usage:"
    echo "  gtask start feature name_of_feature"
    echo "  gtask start hotfix name_of_hotfix"
    echo "  gtask start release name_of_release"
    echo "  gtask finish name_of_feature"
    echo "  gtask finish name_of_hotfix"
    echo "  gtask finish name_of_release"
}

die()
{
    echo >&2 "$@"
    exit 1
}

# Require two arguments
#[ "$#" -eq 2 ] || die "2 arguments required, $# provided"

if [ "$1" == "start" ]; then
    if [ "$2" == "feature" ]; then
        #git checkout development
        #git checkout -b "feature/$2"
        echo "start feature/$3"
    elif [ "$2" == "hotfix" ]; then
        #git checkout master
        #git checkout -b "hotfix/$2"
        echo "start hotfix/$3"
    elif [ "$2" == "release" ]; then
        #git checkout development
        #git checkout -b "release/$2"
        echo "start release/$3"
    else
        usage
        exit
    fi
elif [ "$1" == "finish" ]; then
    current=`git branch | awk '/\*/{print $2}'`
    case ${current} in
        feature* ) echo "finish $2";;
        # If ${current} is feature/*, merge with development
        #git checkout development
        #git merge ${current}
        #git push origin development
        # Prompt to delete ${current} branch
    
        hotfix* ) echo "finish $2";;
        # If ${current} is hotfix/*, merge with master AND development
        # Tag 0.x
        #git checkout master
        #git merge ${current}
        #git push origin master
        #git checkout development
        #git merge ${current}
        #git push origin development
        # Prompt for deletion of ${current} branch
    
        release* ) echo "finish $2";;
        # If ${current} is release/*, ...
        # ...continuously merge bugfixes into development
        #git checkout development
        #git merge ${current}
        #git push origin development
        # ...if done (stable, end of release branch)
            # Tag x.0
            #git checkout master
            #git merge ${current}
            #git push origin master
            # Prompt for deletion of ${current} branch
    esac
else
    usage
    exit
fi
