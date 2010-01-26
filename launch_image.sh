#!/bin/sh

STORAGE=/home/cloud

BASE_IMAGE=$1

COUNT=$(ls $STORAGE/$BASE_IMAGE.*.qcow2 | wc -l)
IMAGE=$STORAGE/$BASE_IMAGE.$COUNT.qcow2
qemu-img create -f qcow2 -b $STORAGE/$BASE_IMAGE $IMAGE > /dev/null 2>&1

TMP=$PWD/.tmp.job
cat > $TMP <<EOF
universe = vm
vm_type = kvm
vm_memory = 512
kvm_disk = /dev/null:null:null
executable = $BASE_IMAGE
+VM_XML="<domain type='kvm'><name>{NAME}</name><memory>524288</memory><vcpu>1</vcpu><os><type arch='i686' machine='pc-0.11'>hvm</type><boot dev='hd'/></os><features><acpi/><apic/><pae/></features><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><devices><emulator>/usr/bin/qemu-kvm</emulator><disk type='file' device='disk'><source file='$IMAGE'/><target dev='hda' bus='ide'/></disk><interface type='network'><source network='default'/><model type='e1000'/></interface><graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/></devices></domain>"
queue
EOF

condor_submit $TMP 

rm $TMP
