#!/bin/sh

STORAGE=/home/cloud

CAT=cat; which pv > /dev/null 2>&1 && CAT=pv

IMAGE=$1

$CAT $IMAGE > $STORAGE/$IMAGE

# libvirt chowns the qcow2 image to qemu.qemu so that qemu can
# read/write it. The base image is not chowned, so we must make sure
# it is readable by qemu. If this is not done, a common VMGahpLog
# error will be:
#   Failed to create libvirt domain: monitor socket did not show up.:
#    No such file or directory
# Other than readable, no one should ever write to the file, so write
# perms are removed.
chmod a=r $STORAGE/$IMAGE

echo "Added $IMAGE"
