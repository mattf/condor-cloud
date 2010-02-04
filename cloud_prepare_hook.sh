#!/bin/sh

source /opt/condor-cloud/functions

while read line; do
   name="${line%% =*}"
   value="${line#*= }"
   case $name in
     Cmd ) BASE_IMAGE="$(echo $value | tr -d '\"')" ;;
     VM_XML ) VM_XML="$line" ;;
   esac
done

get_image $BASE_IMAGE

IMAGE=$(make_image $BASE_IMAGE)

echo $(echo $VM_XML | sed "s:{DISK}:$IMAGE:")

exit 0
