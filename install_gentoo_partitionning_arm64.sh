#!/bin/bash

loadkeys fr

# Create EFI partition
parted /dev/vda mklabel gpt
parted /dev/vda mkpart primary fat32 1MiB 512MiB
parted /dev/vda set 1 boot on

# Create swap partition
parted /dev/vda mkpart primary linux-swap 512MiB 4GiB

# Create ext4 partition for the remaining space
parted /dev/vda mkpart primary ext4 4GiB 100%

# Format partitions
mkfs.fat -F32 /dev/vda1
mkswap /dev/vda2
mkfs.ext4 /dev/vda3

# Mount partitions
mount /dev/vda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/EFI
mount /dev/vda1 /mnt/gentoo/boot/EFI
swapon /dev/vda2

# Download stage3
cd /mnt/gentoo
wget https://distfiles.gentoo.org/releases/arm64/autobuilds/20240329T230405Z/stage3-arm64-openrc-20240329T230405Z.tar.xz

# Extract stage3 archive with specified options
tar xpvf stage3-arm64-openrc-20240329T230405Z.tar.xz --xattrs-include='*.*' --numeric-owner

MAKE_CONF="/mnt/gentoo/etc/portage/make.conf"
# Modify variables in make.conf

NUM_CORES=$(nproc)
sed -i '/COMMON_FLAGS=/s/=.*/="-march=armv8-a -O2 -pipe"/' $MAKE_CONF
echo "MAKEOPTS=\"-j$NUM_CORES\"" >> "$MAKE_CONF"
echo 'L10N="fr"' >> $MAKE_CONF
echo 'VIDEO_CARDS="fbdev vesa"' >> $MAKE_CONF
echo 'INPUT_DEVICES="libinput keyboard mouse"' >> $MAKE_CONF
echo 'EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --quiet-build=y"' >> $MAKE_CONF
echo 'PORTAGE_SCHEDULING_POLICY="idle"' >> $MAKE_CONF
echo 'GENTOO_MIRRORS="ftp://ftp.free.fr/mirrors/ftp.gentoo.org/ \
    http://ftp.free.fr/mirrors/ftp.gentoo.org/ \
    https://mirrors.ircam.fr/pub/gentoo-distfiles/ \
    rsync://mirrors.ircam.fr/pub/gentoo-distfiles/ \
    https://gentoo.mirrors.ovh.net/gentoo-distfiles/"' >> "$MAKE_CONF"


# Create necessary directories and copy repos.conf file
mkdir -p /mnt/gentoo/etc/portage/repos.conf
mkdir -p /mnt/gentoo/var/db/repos/gentoo
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# Copy the chroot commands script into the chroot environment
CHROOT_SCRIPT="install_gentoo_chroot_commands.sh"
cp "/root/$CHROOT_SCRIPT" "/mnt/gentoo/root/$CHROOT_SCRIPT"

cp -L /etc/resolv.conf /mnt/gentoo/etc/

# Mount proc, dev, and sys filesystems
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /dev /mnt/gentoo/dev
mount --rbind /sys /mnt/gentoo/sys

chroot /mnt/gentoo /bin/bash -c "chmod +x /root/$CHROOT_SCRIPT && /root/$CHROOT_SCRIPT"

