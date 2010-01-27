#!/bin/sh

STORAGE=/home/cloud

function image_exists() {
   IMAGE="$1"
   test -e $STORAGE/$IMAGE
}

function usage() {
   echo "usage: $0 [-t <small|medium|large>] -i <image>"
   exit 1
}

TYPE="small"

while getopts ":t:i:" opt; do
   case $opt in
     t) TYPE="$OPTARG"
        case $TYPE in
	  small|medium|large) ;;
	  *) echo "Invalid type (-t), try small, medium or large"
	     usage
	     ;;
        esac
        ;;
     i) BASE_IMAGE="$OPTARG" ;;
     :) echo "Missing argument to -$OPTARG"
        usage
        ;;
     ?) echo "Invalid option -$OPTARG"
        usage
        ;;
   esac
done

if [ -z "$BASE_IMAGE" ]; then
   echo "Missing image (-i)"
   usage
fi

if ! image_exists $BASE_IMAGE; then
   echo "Image '$BASE_IMAGE' does not exist, find one with list_images.sh"
   exit 2
fi

case $TYPE in
  small)
    MEMORY_MB=512
    CPU=1
    ;;
  medium)
    MEMORY_MB=1024
    CPU=2
    ;;
  large)
    # 2GB = 2047MB for now, else error - qemu: at most 2047 MB RAM can be simulated
    MEMORY_MB=2047
    CPU=4
    ;;
esac

TMP=$(mktemp $PWD/.tmp.XXXXXX)
cat > $TMP <<EOF
universe = vm
vm_type = kvm
vm_memory = $MEMORY_MB
request_cpus = $CPU
kvm_disk = /dev/null:null:null
executable = $BASE_IMAGE
+HookKeyword="CLOUD"
+VM_XML="<domain type='kvm'><name>{NAME}</name><memory>$((MEMORY_MB * 1024))</memory><vcpu>$CPU</vcpu><os><type arch='i686' machine='pc-0.11'>hvm</type><boot dev='hd'/></os><features><acpi/><apic/><pae/></features><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><devices><emulator>/usr/bin/qemu-kvm</emulator><disk type='file' device='disk'><source file='{DISK}'/><target dev='hda' bus='ide'/></disk><interface type='network'><source network='default'/><model type='e1000'/></interface><graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/></devices></domain>"
queue
EOF

ID=$(condor_submit $TMP | grep "cluster" | sed 's/.*cluster \([^\.]*\)./\1/') 2> /dev/null
echo "Launching $BASE_IMAGE in a $TYPE instance (Memory=${MEMORY_MB}MB, CPUs=$CPU), id is $ID."

rm $TMP
