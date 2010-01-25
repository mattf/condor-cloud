#!/bin/sh

STORAGE=/home/matt/Cloud/STORAGE

CAT=cat; which pv > /dev/null 2>&1 && CAT=pv

IMAGE=$1

$CAT $IMAGE > $STORAGE/$IMAGE

echo "Added $IMAGE"
