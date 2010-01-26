#!/bin/sh

STORAGE=/home/cloud

cd $STORAGE
for i in $(echo * | tr ' ' '\n' | grep -v .qcow2); do
   IMAGES="$i,$IMAGES"
done

echo "CACHED_IMAGES=\"$IMAGES\""

exit 0
