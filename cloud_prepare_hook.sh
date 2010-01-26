#!/bin/sh

STORAGE=/home/cloud

while read line; do
   name="${line%% =*}"
   value="${line#*= }"
   case $name in
     Cmd ) BASE_IMAGE="$(echo $value | tr -d '\"')" ;;
     VM_XML ) VM_XML="$line" ;;
   esac
done

COUNT=$(ls $STORAGE/$BASE_IMAGE.*.qcow2 2> /dev/null | wc -l)
IMAGE=$STORAGE/$BASE_IMAGE.$COUNT.qcow2
qemu-img create -f qcow2 -b $STORAGE/$BASE_IMAGE $IMAGE > /dev/null 2>&1

echo $(echo $VM_XML | sed "s:{DISK}:$IMAGE:")

exit 0
