#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

[ -z "$SYSTEM_ROOT" ] && SYSTEM_ROOT=""
[ -z "$BOOT_ROOT" ] && BOOT_ROOT="/flash"
[ -z "$BOOT_PART" ] && BOOT_PART=$(df "$BOOT_ROOT" | tail -1 | awk {' print $1 '})

# identify the boot device
if [ -z "$BOOT_DISK" ]; then
  case $BOOT_PART in
    /dev/mmcblk*) BOOT_DISK=$(echo $BOOT_PART | sed -e "s,p[0-9]*,,g");;
  esac
fi

# mount $BOOT_ROOT rw
mount -o remount,rw $BOOT_ROOT

if [ ! -d "$BOOT_ROOT/device_trees" ]; then
  mkdir $BOOT_ROOT/device_trees
  mv $BOOT_ROOT/*.dtb $BOOT_ROOT/device_trees
  if [ -f "$BOOT_ROOT/extlinux/extlinux.conf" ]; then
    if ! grep -q "device_trees" $BOOT_ROOT/extlinux/extlinux.conf; then
      sed -i 's/FDT /FDT \/device_trees/g' $BOOT_ROOT/extlinux/extlinux.conf
      sed -i 's/FDTDIR \//FDTDIR \/device_trees/g' $BOOT_ROOT/extlinux/extlinux.conf
    fi
  fi
fi

echo "Updating device trees..."
cp -f $SYSTEM_ROOT/usr/share/bootloader/device_trees/* $BOOT_ROOT/device_trees

# The SPL boots u-boot from the GPT partition named "uboot" (created by mkimage
# in the pre-system gap). Update it in place by writing the DHTB image to that
# partition, located by its GPT partition label rather than a hardcoded number.
if [ -f "$SYSTEM_ROOT/usr/share/bootloader/uboot.bin" ]; then
  UBOOT_PART=$(readlink -f /dev/disk/by-partlabel/uboot 2>/dev/null)
  if [ -b "$UBOOT_PART" ]; then
    echo "Updating uboot.bin on $UBOOT_PART..."
    dd if=$SYSTEM_ROOT/usr/share/bootloader/uboot.bin of=$UBOOT_PART \
       conv=fsync &>/dev/null
  else
    echo "WARNING: no uboot partition found (by-partlabel/uboot); skipping u-boot update"
  fi
fi

# mount $BOOT_ROOT ro
sync
mount -o remount,ro $BOOT_ROOT

echo "UPDATE" > /storage/.boot.hint
