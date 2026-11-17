#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

# MediaTek LK devices boot the kernel from the internal boot partition, not
# from the boot filesystem on the SD card. After an update has replaced KERNEL
# (an Android boot image) on the boot filesystem, write it to the boot partition
# of the slot we are running from.
#
# Safety rules:
#  - Only slot B is ever written. Slot A holds Android and is the fallback the
#    bootloader returns to when slot B fails to boot.
#  - Nothing is written unless the file "mtk-lk-write-boot" exists on the boot
#    filesystem. Remove it to keep the internal storage untouched and write the
#    boot partition by hand instead.
#  - The write is skipped when the partition already holds this image, and is
#    read back and compared afterwards.

[ -z "$SYSTEM_ROOT" ] && SYSTEM_ROOT=""
[ -z "$BOOT_ROOT" ] && BOOT_ROOT="/flash"

ALLOW_FILE="$BOOT_ROOT/mtk-lk-write-boot"
KERNEL_IMG="$BOOT_ROOT/KERNEL"

slot_suffix() {
  # The bootloader passes the slot through bootconfig, older ones on the command line.
  s=$(sed -n 's/^androidboot\.slot_suffix *= *"\{0,1\}\(_[ab]\)"\{0,1\}.*/\1/p' /proc/bootconfig 2>/dev/null | head -n 1)
  [ -z "$s" ] && s=$(tr ' ' '\n' < /proc/cmdline | sed -n 's/^androidboot\.slot_suffix=\(_[ab]\)$/\1/p' | head -n 1)
  echo "$s"
}

part_by_name() {
  for u in /sys/class/block/*/uevent; do
    if grep -q "^PARTNAME=$1\$" "$u" 2>/dev/null; then
      echo "/dev/$(sed -n 's/^DEVNAME=//p' "$u")"
      return 0
    fi
  done
  return 1
}

update_boot_partition() {
  [ -f "$KERNEL_IMG" ] || { echo "mtk-lk: no KERNEL on $BOOT_ROOT, nothing to do"; return 0; }

  SLOT=$(slot_suffix)
  if [ "$SLOT" != "_b" ]; then
    echo "mtk-lk: running from slot '${SLOT:-unknown}', not _b: boot partition left alone"
    return 0
  fi

  PART=$(part_by_name "boot$SLOT") || { echo "mtk-lk: boot$SLOT partition not found"; return 1; }
  IMG_SIZE=$(stat -c %s "$KERNEL_IMG")
  PART_SIZE=$(( $(cat "/sys/class/block/$(basename "$PART")/size") * 512 ))
  if [ "$IMG_SIZE" -gt "$PART_SIZE" ]; then
    echo "mtk-lk: KERNEL ($IMG_SIZE bytes) is larger than boot$SLOT ($PART_SIZE bytes)"
    return 1
  fi

  WANT=$(sha256sum "$KERNEL_IMG" | cut -d' ' -f1)
  HAVE=$(head -c "$IMG_SIZE" "$PART" | sha256sum | cut -d' ' -f1)
  if [ "$WANT" = "$HAVE" ]; then
    echo "mtk-lk: boot$SLOT already holds this kernel"
    return 0
  fi

  if [ ! -f "$ALLOW_FILE" ]; then
    echo "mtk-lk: boot$SLOT differs from KERNEL but $(basename "$ALLOW_FILE") is not present."
    echo "mtk-lk: write KERNEL to boot$SLOT by hand, or create that file on the boot filesystem."
    return 0
  fi

  echo "mtk-lk: writing KERNEL to boot$SLOT ($PART)..."
  blockdev --setrw "$PART" 2>/dev/null
  dd if="$KERNEL_IMG" of="$PART" bs=4M conv=fsync 2>/dev/null || { echo "mtk-lk: write failed"; return 1; }
  sync
  echo 3 > /proc/sys/vm/drop_caches
  BACK=$(head -c "$IMG_SIZE" "$PART" | sha256sum | cut -d' ' -f1)
  if [ "$WANT" != "$BACK" ]; then
    echo "mtk-lk: READ-BACK MISMATCH on boot$SLOT. The old kernel is gone and the new one is not"
    echo "mtk-lk: intact; the bootloader will fall back to slot A after its retries."
    return 1
  fi
  echo "mtk-lk: boot$SLOT updated and verified"
}

update_boot_partition

echo "UPDATE" > /storage/.boot.hint
