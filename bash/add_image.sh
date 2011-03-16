#!/bin/sh

source /opt/condor-cloud/functions

put_image $1
if [ $? -ne 0 ]; then
   echo "Add failed: $ERROR_MSG"
else
   echo "Added $1"
fi
