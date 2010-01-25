#!/bin/sh

STORAGE=/home/matt/Cloud/STORAGE

cd $STORAGE
for i in $(echo * | tr ' ' '\n' | grep -v .qcow2); do
   echo $i
done

exit 0

