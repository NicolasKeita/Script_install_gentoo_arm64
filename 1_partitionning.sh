#!/bin/bash
set -e

# Variables
DEVICE="/dev/sda"
EFI_PARTITION="${DEVICE}1"
SWAP_PARTITION="${DEVICE}2"
ROOT_PARTITION="${DEVICE}3"
GENTOO_MIRROR="https://distfiles.gentoo.org/releases/arm64/autobuilds/20240329T230405Z/stage3-arm64-openrc-20240329T230405Z.tar.xz"
MAKE_CONF="/mnt/gentoo/etc/portage/make.conf"
#CHROOT_SCRIPT="install_gentoo_chroot_commands.sh"
CHROOT_SCRIPT="2.sh"
REPOS_CONF="/mnt/gentoo/etc/portage/repos.conf/gentoo.conf"

# Function to print messages
print_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to mount partitions
mount_partitions() {
    print_message "Mounting partitions..."
    mkdir -p /mnt/gentoo/boot/efi
    mount "$EFI_PARTITION" /mnt/gentoo/boot/efi
    swapon "$SWAP_PARTITION"
    mount "$ROOT_PARTITION" /mnt/gentoo
}

# Function to download stage3
download_stage3() {
    print_message "Downloading stage3..."
    cd /mnt/gentoo
    wget "$GENTOO_MIRROR"
    tar xpvf stage3-arm64-openrc-20240329T230405Z.tar.xz --xattrs-include='*.*' --numeric-owner
}

# Function to configure make.conf
configure_make_conf() {
    print_message "Configuring make.conf..."
    NUM_CORES=$(nproc)
    sed -i '/COMMON_FLAGS=/s/=.*/="-march=armv8-a -O2 -pipe"/' "$MAKE_CONF"
    echo "MAKEOPTS=\"-j$NUM_CORES\"" >> "$MAKE_CONF"
    echo 'FEATURES="buildpkg"' >> "$MAKE_CONF"
    echo 'L10N="fr"' >> "$MAKE_CONF"
    echo 'VIDEO_CARDS="fbdev vesa"' >> "$MAKE_CONF"
    echo 'INPUT_DEVICES="libinput keyboard mouse"' >> "$MAKE_CONF"
    echo 'EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --quiet-build=y"' >> "$MAKE_CONF"
    echo 'PORTAGE_SCHEDULING_POLICY="idle"' >> "$MAKE_CONF"
    echo 'GENTOO_MIRRORS="ftp://ftp.free.fr/mirrors/ftp.gentoo.org/ \
        http://ftp.free.fr/mirrors/ftp.gentoo.org/ \
        https://mirrors.ircam.fr/pub/gentoo-distfiles/ \
        rsync://mirrors.ircam.fr/pub/gentoo-distfiles/ \
        https://gentoo.mirrors.ovh.net/gentoo-distfiles/"' >> "$MAKE_CONF"
}

# Main script
print_message "Starting Gentoo installation script..."

# Partitioning
print_message "Partitioning disk..."
parted "$DEVICE" mklabel gpt
parted "$DEVICE" mkpart primary fat32 1MiB 512MiB
parted "$DEVICE" set 1 boot on
parted "$DEVICE" mkpart primary linux-swap 512MiB 4GiB
parted "$DEVICE" mkpart primary ext4 4GiB 100%

# Formatting partitions
print_message "Formatting partitions..."
mkfs.fat -F32 "$EFI_PARTITION"
mkswap "$SWAP_PARTITION"
mkfs.ext4 "$ROOT_PARTITION"

# Mounting partitions
mount_partitions

# Downloading stage3
download_stage3

# Configuring make.conf
configure_make_conf

# Copying repos.conf file
print_message "Copying repos.conf file..."
mkdir -p /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf "$REPOS_CONF"

# Copying chroot commands script
print_message "Copying chroot commands script..."
cp -L /etc/resolv.conf /mnt/gentoo/etc/
cp "/root/$CHROOT_SCRIPT" "/mnt/gentoo/root/$CHROOT_SCRIPT"

# Mounting proc, dev, and sys filesystems
print_message "Mounting proc, dev, and sys filesystems..."
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /dev /mnt/gentoo/dev
mount --rbind /sys /mnt/gentoo/sys

# Chrooting and executing chroot commands script
print_message "Chrooting and executing chroot commands script..."
chroot /mnt/gentoo /bin/bash -c "chmod +x /root/$CHROOT_SCRIPT && /root/$CHROOT_SCRIPT"

print_message "Gentoo installation script completed successfully."
