#!/bin/sh

source /opt/condor-cloud/functions

cd $STORAGE
for i in $(echo * | tr ' ' '\n' | grep -v -e '*' -e .qcow2); do
   echo $i
done

exit 0

