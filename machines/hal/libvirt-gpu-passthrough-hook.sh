#!/run/current-system/sw/bin/bash

# Debugging
set -x
exec &>>/tmp/libvirt-hook
# BASH_XTRACEFD=19
date


#
#IOMMU Group 17:
#        07:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD104 [GeForce RTX 4070] [10de:2786] (rev a1)
#        07:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:22bc] (rev a1)

VIRSH_GPU_VIDEO=pci_0000_07_00_0
VIRSH_GPU_AUDIO=pci_0000_07_00_1

GUEST_NAME=$1
ACTION=$2
STATE_NAME=$3

if [ $GUEST_NAME != "$GUEST_NAME" ]; then
    echo "guest name does not match: $GUEST_NAME"
    exit 0
fi

if [ $ACTION = "prepare" ]; then
    # Isolate host to core 0
    #systemctl set-property --runtime -- user.slice AllowedCPUs=0
    #systemctl set-property --runtime -- system.slice AllowedCPUs=0
    #systemctl set-property --runtime -- init.scope AllowedCPUs=0

    # Stop display manager
    #systemctl stop display-manager.service

    # make sure gnome remote desktop is also stopped
    runuser -l bara -c 'systemctl --user stop gnome-remote-desktop.service'

    # Unbind VTconsoles
    echo 0 > /sys/class/vtconsole/vtcon0/bind
    echo 0 > /sys/class/vtconsole/vtcon1/bind

    # Unbind EFI Framebuffer
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

    # Avoid race condition
    sleep 1

    # this will try to reload the modules
    systemctl stop coolercontrold.service

    # Unload NVIDIA kernel modules
    modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

    # Detach GPU devices from host
    #virsh nodedev-detach $VIRSH_GPU_VIDEO
    #virsh nodedev-detach $VIRSH_GPU_AUDIO

    # Load vfio module
    modprobe vfio-pci
fi

if [ $ACTION = "started" ]; then
    # this will try to reload the modules
    systemctl start coolercontrold.service
fi

if [ $ACTION = "release" ]; then
    # Unload vfio module
    modprobe -r vfio-pci

    # Attach GPU devices from host
    #virsh nodedev-reattach $VIRSH_GPU_VIDEO
    #virsh nodedev-reattach $VIRSH_GPU_AUDIO

    # Load NVIDIA kernel modules
    modprobe -a nvidia_drm nvidia_modeset nvidia_uvm nvidia

    # Avoid race condition
    sleep 1

    # Bind EFI Framebuffer
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind

    # Bind VTconsoles
    echo 1 > /sys/class/vtconsole/vtcon0/bind
    echo 1 > /sys/class/vtconsole/vtcon1/bind

    # Start display manager
    #systemctl start display-manager.service

    # Return host to all cores
    #systemctl set-property --runtime -- user.slice AllowedCPUs=0-3
    #systemctl set-property --runtime -- system.slice AllowedCPUs=0-3
    #systemctl set-property --runtime -- init.scope AllowedCPUs=0-3

    # reinitialize coolercontrold to query gpu temp
    systemctl restart coolercontrold.service
fi
