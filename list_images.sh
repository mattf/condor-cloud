#!/bin/sh

STORAGE=/home/cloud

cd $STORAGE
for i in $(echo * | tr ' ' '\n' | grep -v .qcow2); do
   echo $i
done

exit 0

