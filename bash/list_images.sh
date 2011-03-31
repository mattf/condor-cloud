#!/bin/sh

source /usr/libexec/condor/cloud_functions

cd $STORAGE
for i in $(echo * | tr ' ' '\n' | grep -v -e '*' -e .qcow2); do
   echo $i
done

exit 0

