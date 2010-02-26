#!/bin/sh

source /opt/condor-cloud/functions

cd $CACHE
echo "CACHED_IMAGES=\"$(echo * | tr ' ' '\n' | grep -v .qcow2 | tr '\n' ',')\""

exit 0
