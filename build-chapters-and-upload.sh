#!/bin/bash

TEMP_DIR=/tmp
SVN_REPO=svn+ssh://scm.gforge.inria.fr/svn/pharobooks
REMOTE_SERVER=scm.gforge.inria.fr
REMOTE_PATH=/home/groups/pharobooks/htdocs
REMOTE=$REMOTE_SERVER:$REMOTE_PATH
BOOK=PharoByExampleTwo-Eng
DOWNLOAD_URL=http://pharobooks.gforge.inria.fr/PharoByExampleTwo-Eng

cd $TEMP_DIR
rm -rf $BOOK
svn co $SVN_REPO/$BOOK
cd $BOOK

chapters=$(cat PBE2.tex  | grep '^\\input' | grep -v common.tex | sed -e 's/^\\input{\([^}]*\)}.*$/\1/')

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
files_to_upload=$(echo $chapters | sed 's/\.tex/.pdf/g')

mkdir tmp
mv $files_to_upload tmp/
cd tmp

echo
echo "Uploading to $DOWNLOAD_URL..."
echo

tar vcf - *.pdf | \
    ssh $USER@$REMOTE_SERVER \
    "cd $REMOTE_PATH/$BOOK; mkdir $upload_id; cd $upload_id; tar vxf -; cd ..; unlink latest; ln -s $upload_id latest"
