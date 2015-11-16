#!/bin/bash

if [ $# -ne 1 ];
then
    echo "Usage: $0 file changed";
    exit -1
fi

git add $1
git status
git commit -m "commit from tool"
git push origin master

