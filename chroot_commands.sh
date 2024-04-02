#!/bin/bash

# Variables
LOG_FILE="/var/log/gentoo_setup.log"
DISK_NAME="/dev/vda"

# Logging function
log_message() {
    echo "$(date +"%Y-%m-%d %T"): $1" >> "$LOG_FILE"
}

# Set chroot prompt
source /etc/profile

# Update package repositories
log_message "Updating package repositories..."
emerge-webrsync

# Install CPU flags package
log_message "Installing CPU flags package..."
emerge --oneshot --quiet app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

# Create package license file
log_message "Creating package license file..."
mkdir -p /etc/portage/package.license
echo "*/* *" >> /etc/portage/package.license/custom

# Clean up unused dependencies
log_message "Cleaning up unused dependencies..."
emerge --depclean

# Set timezone
log_message "Setting timezone to Europe/Paris..."
echo "Europe/Paris" > /etc/timezone

# Install Linux firmware
log_message "Installing Linux firmware..."
emerge --quiet sys-kernel/linux-firmware

# Create /etc/fstab file
log_message "Creating /etc/fstab file..."
EFI_UUID=$(blkid -s UUID -o value ${DISK_NAME}1)
cat <<EOF > /etc/fstab
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

# ${DISK_NAME}1 is the EFI system partition
UUID=${EFI_UUID}  /boot/efi  vfat  umask=0077  0  2

# ${DISK_NAME}2 is the swap partition
${DISK_NAME}2  none  swap  defaults  0  0

# ${DISK_NAME}3 is the root partition
${DISK_NAME}3  /  ext4  defaults  0  1
EOF

# End of script
log_message "Setup completed successfully!"

