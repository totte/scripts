#!/bin/sh

# gittask.sh: taskbased git branching utility

# This script requires that git has been installed and properly configured,
# that the remote "master" and "development" branches exist (locally too) 
# and that a network connection to the "origin" repository is established.
# It also requires that you have a GPG private key to sign tags.

# Copyright 2012 Hans "Totte" Tovetjärn, totte@tott.es
# All rights reserved. See LICENSE for more information.

set -o errexit

usage()
{
    echo
    echo "Usage:"
    echo "  gittask.sh new topic name_of_topic"
    echo "    - Creates a new branch off from 'development' named"
    echo "      'topic/name_of_topic'."
    echo "  gittask.sh new release name_of_release"
    echo "    - Creates a new branch off from 'development' named"
    echo "      'release/name_of_release'."
    echo "  gittask.sh new hotfix name_of_hotfix"
    echo "    - Creates a new branch off from 'master' named"
    echo "      'hotfix/name_of_hotfix'."
    echo "  gittask.sh done"
    echo "    - Merges current branch into master and/or development"
    echo "      depending on if it's a topic, release or hotfix."
}

delete_branch()
{
    # Infinite loop, only way out (except for Ctrl+C) is to answer yes or no.
    while true; do
        echo "Delete $current branch? (y/n) "
        read yn
        case $yn in
            [Yy]* ) 
                git branch -d ${current}
                break
                ;;
            [Nn]* )
                echo "Leaving $current branch as it is."
                break
                ;;
            * )
                echo "Error: Answer (y)es or (n)o."
                ;;
        esac
    done
}

define_tag()
{
    # Don't proceed until both variables have been set.
    while [ -z ${version_number} ] && [ -z ${version_note} ]; do
        echo "Enter version number (major.minor.fix): "
        read version_number
        echo "Enter version number note: "
        read version_note
    done
}

# Confirm that user is in a git repository, abort otherwise.
git status >/dev/null 2>&1 || { echo "Error: You're not in a git repository."; exit 1; }

# If "new", confirm that the required arguments were provided.
if [ "$1" == "new" ] && [ -n "$2" ] && [ -n "$3" ]; then
    
    # Validate $3, only allow a-z (lower case), 0-9, . and _ (underscore) in branch names.
    [ "${3//[0-9a-z._]/}" = "" ] || { echo "Error: Branch names may only consist of a-z, 0-9 and _ (underscore) characters."; exit 1; }
    case $2 in
        topic )
            git checkout development
            git checkout -b "topic/$3"
            exit 0
            ;;
        release )
            git checkout development
            git checkout -b "release/$3"
            exit 0
            ;;
        hotfix )
            git checkout master
            git checkout -b "hotfix/$3"
            exit 0
            ;;
        * )
            echo "Error: You didn't specify topic, release or hotfix."
            exit 1
            ;;
    esac

# If "done", proceed to determine current branch and by that what to do next.
elif [ "$1" == "done" ]; then
    current=`git branch | awk '/\*/{print $2}'`
    case ${current} in
        topic* )
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;
        release* )
            git checkout development
            git merge ${current}
            git push origin development
            
            # Infinite loop, only way out (except for Ctrl+C) is to answer yes or no.
            while true; do
                echo "Merge into master and make a release? (y/n) "
                read yn
                case $yn in
                    [Yy]* )
                        git checkout master
                        git merge ${current}
                        define_tag
                        git tag -s ${version_number} -m "${version_note}"
                        git push --tags origin master
                        delete_branch
                        break
                        ;;
                    [Nn]* )
                        echo "Leaving master branch as it is."
                        break
                        ;;
                    * )
                        echo "Error: Answer (y)es or (n)o."
                        ;;
                esac
            done
            exit 0
            ;;
        hotfix* )
            git checkout master
            git merge ${current}
            define_tag
            git tag -s ${version_number} -m ${version_note}
            git push --tags origin master
            git checkout development
            git merge ${current}
            git push origin development
            delete_branch
            exit 0
            ;;
        * )
            echo "Error: You're not on a topic, release or hotfix branch."
            exit 1
            ;;
    esac
else
    echo "Error: You didn't provide the needed arguments."
    usage
    exit 1
fi
