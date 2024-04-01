#!/bin/bash

# Determine the UUID of the EFI system partition
EFI_UUID=$(blkid -s UUID -o value /dev/vda1)

# Create the /etc/fstab file
cat <<EOF > /etc/fstab
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

# /dev/vda1 is the EFI system partition
UUID=${EFI_UUID}  /boot/efi  vfat  umask=0077  0  2

# /dev/vda2 is the swap partition
/dev/vda2  none  swap  defaults  0  0

# /dev/vda3 is the root partition
/dev/vda3  /  ext4  defaults  0  1
EOF

echo "Created /etc/fstab file."
