#!/bin/sh

source /opt/condor-cloud/functions

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

if ! image_exists_global $BASE_IMAGE; then
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
# Use the Virtual Machine (VM) Universe, duh
universe = vm

# We'll be doing KVM only, obvi
vm_type = kvm

# Partitionable Slot Parameters: vm_memory (request_memory) and request_cpus

# Ideally just request_memory, but VM Universe jobs require vm_memory
# and the default request_memory uses vm_memory
vm_memory = $MEMORY_MB

# Number of CPUs to consume, clearly
request_cpus = $CPU

# Required parameter for VM Universe, but we are using a special
# libvirt XML configuration generating script that entirely ignores
# this, so we effectively null it out.
kvm_disk = /dev/null:null:null

# Only a name, but also used by the cloud prepare hook to setup and
# set {DISK} inside VM_XML.
executable = $BASE_IMAGE

# Invoke the CLOUD prepare hook before execution. It will setup the
# VM's disk.
+HookKeyword="CLOUD"

# libvirt domain XML, processed by the cloud prepare hook and libvirt
# XML config script. Basically, the libvirt XML config script just
# echos this after assigning {NAME}.
## NOTE on EL5:
##  qemu-kvm is in /usr/libexec on EL5
##  arch needs to be x86_64
##  machine needs to be pc
## NOTE on br0:
##  http://www.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/5.4/html/Virtualization_Guide/sect-Virtualization-Network_Configuration-Bridged_networking_with_libvirt.html
##  http://wiki.libvirt.org/page/Networking#Bridged_networking_.28aka_.22shared_physical_device.22.29
+VM_XML="<domain type='kvm'><name>{NAME}</name><memory>$((MEMORY_MB * 1024))</memory><vcpu>$CPU</vcpu><os><type arch='i686' machine='pc-0.11'>hvm</type><boot dev='hd'/></os><features><acpi/><apic/><pae/></features><clock offset='utc'/><on_poweroff>destroy</on_poweroff><on_reboot>restart</on_reboot><on_crash>restart</on_crash><devices><emulator>/usr/bin/qemu-kvm</emulator><disk type='file' device='disk'><source file='{DISK}'/><target dev='hda' bus='ide'/></disk><interface type='bridge'><source bridge='br0'/><model type='e1000'/></interface><graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/></devices></domain>"
queue
EOF

ID=$(condor_submit $TMP | grep "cluster" | sed 's/.*cluster \([^\.]*\)./\1/') 2> /dev/null
echo "Launching $BASE_IMAGE in a $TYPE instance (Memory=${MEMORY_MB}MB, CPUs=$CPU), id is $ID."

rm $TMP
