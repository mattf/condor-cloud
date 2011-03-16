#!/bin/sh

source /opt/condor-cloud/functions

cd $CACHE
echo "CACHED_IMAGES=\"$(echo * | tr ' ' '\n' | grep -v -e '*' -e .qcow2 | tr '\n' ',')\""

exit 0
