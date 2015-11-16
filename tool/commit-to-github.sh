#!/bin/bash

#if [ $# -ne 1 ];
#then
#    echo "Usage: $0 file changed";
#    exit -1
#fi

modified_files=`git status | awk ' /modified:/ {print $2}'`
git add $modified_files
git status
git commit -m "commit from tool"
git push origin master

