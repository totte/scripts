#!/bin/sh
# task.sh: taskbased git branch management utility

usage()
{
    echo "Usage:"
    echo "  task.sh new feature name_of_feature"
    echo "  task.sh new release name_of_release"
    echo "  task.sh new hotfix name_of_hotfix"
    echo "  task.sh done (affects current branch)"
}

delete_branch()
{
    while true; do
        echo "Delete branch $current? "
        read yn
        case $yn in
            [Yy]* ) 
                git branch -d ${current}
                break
                ;;
            [Nn]* )
                echo "Leaving branch $current as it is."
                break
                ;;
            * )
                echo "Error: Please answer (y)es or (n)o."
                ;;
        esac
    done
}

define_tag()
{
    while [ -z ${version_number} && -z ${version_note} ]; do
        echo "Enter version number (major.minor.fix): "
        read version_number
        echo "Enter version number note: "
        read version_note
    done
}

if [ "$1" == "new" ] && [ -z "$2" ] && [ -z "$3" ]; then
    case $2 in
        feature )
            git checkout development
            git checkout -b "feature/$3"
            ;;
        release )
            git checkout development
            git checkout -b "release/$3"
            ;;
        hotfix )
            git checkout master
            git checkout -b "hotfix/$3"
            ;;
        * )
            echo "Error: You didn't specify feature, release or hotfix."
            usage
            exit 1
            ;;
    esac
elif [ "$1" == "done" ]; then
    current=`git branch | awk '/\*/{print $2}'`
    case ${current} in
        feature* )
            echo "Merging into development branch..."
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;

        release* )
            echo "Merging into development branch..."
            git checkout development
            git merge ${current}
            git push origin development
            while true; do
                echo "Merge into master (make a release)? "
                read yn
                case $yn in
                    [Yy]* ) 
                        git checkout master
                        git merge ${current}
                        define_tag
                        git tag -s $version_number -m $version_note
                        git push --tags origin master
                        delete_branch
                        exit 0
                        ;;
                    [Nn]* )
                        echo "Leaving branch master as it is."
                        exit 0
                        ;;
                    * )
                        echo "Error: Please answer (y)es or (n)o."
                        ;;
                esac
            done
            exit 0
            ;;
        
        hotfix* )
            git checkout master
            git merge ${current}
            define_tag
            git tag -s $version_number -m $version_note
            git push --tags origin master
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;
    
        * )
            echo "Error: You're not on a feature, release or hotfix branch."
            usage
            exit 1
            ;;
    esac
else
    echo "Error: You didn't specify whether you want to start or finish a task."
    usage
    exit 1
fi
