#!/bin/bash

source /etc/profile
export PS1="(chroot) $PS1"

emerge-webrsync --quiet
emerge --sync --quiet

emerge --oneshot --quiet app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

