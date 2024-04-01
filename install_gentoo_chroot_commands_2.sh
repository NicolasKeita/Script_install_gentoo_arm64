#!/bin/bash

# Variables
LOG_FILE="/var/log/gentoo_setup.log"

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

#create fstab file
bash create_fstab.sh

# End of script
log_message "Setup completed successfully!"
