#!/bin/bash

TEMP_DIR=/tmp
SVN_REPO=svn+ssh://scm.gforge.inria.fr/svn/pharobooks
REMOTE=scm.gforge.inria.fr:/home/groups/pharobooks/htdocs
BOOK=PharoByExampleTwo-Eng
USER=cassou

cd $TEMP_DIR
rm -rf $BOOK
svn co $SVN_REPO/$BOOK
cd $BOOK

chapters=$(cat PBE2.tex  | grep '^\\input' | grep -v common.tex | sed -e 's/^\\input{\([^}]\+\)}.*$/\1/')

# First try to compile all chapters before uploading anything
for chapter in $chapters; do
    echo ======================================================================
    echo COMPILING $chapter
    echo ======================================================================

    file=$(basename $chapter)
    cd $(dirname $chapter)
    pdflatex $file
    pdflatex $file
    cd ..
done

upload_id=$(date -u +%F_%T)

echo mkdir $upload_id | sftp $USER@$REMOTE/$BOOK
if [[ $? -ne 0 ]]; then
    echo "Was not able to create remote directory!"
    exit 1
fi

files_to_upload=$(echo $chapters | sed 's/\.tex/.pdf/g')
scp $files_to_upload $USER@$REMOTE/$BOOK/$upload_id/
if [[ $? -ne 0 ]]; then
    echo "Was not able to upload chapters to $REMOTE"
    exit 1
fi

echo "rm latest" | sftp $USER@$REMOTE/$BOOK
if [[ $? -ne 0 ]]; then
    echo "Was not able to create 'latest' symlink!"
    exit 1
fi

echo "symlink $upload_id latest" | sftp $USER@$REMOTE/$BOOK
if [[ $? -ne 0 ]]; then
    echo "Was not able to create 'latest' symlink!"
    exit 1
fi
