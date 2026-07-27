# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="u-boot"
PKG_VERSION="34afab15d051a89ebfc4d2dd1c8cda8e1ce56ea9"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/beebono/u-boot-ums512"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="main"
PKG_GIT_CLONE_SINGLE="yes"
PKG_DEPENDS_TARGET="toolchain Python3"
PKG_LONGDESC="Unisoc UMS512/T618 vendor U-Boot fork for the Anbernic RG Rotate."
PKG_TOOLCHAIN="manual"

PKG_NEED_UNPACK="${PROJECT_DIR}/${PROJECT}/bootloader ${PROJECT_DIR}/${PROJECT}/devices/${DEVICE}/bootloader"

# This is the Spreadtrum vendor U-Boot, not mainline: it builds under ARCH=arm
# (CONFIG_ARM=y, no CONFIG_ARM64) with the aarch64 cross toolchain, and the
# board is selected by DEVICE_TREE rather than by a dtb make target.
PKG_UBOOT_CONFIG="ums512_rg_rotate_defconfig"
PKG_UBOOT_DEVICE_TREE="ums512_rg_rotate"

make_target() {
  setup_pkg_config_host

  # GCC 14 hates this older vendor code, and we know it works on device so
  # just make it build by downgrading warnings and setting an older std.
  local UBOOT_KCFLAGS="-std=gnu11 \
    -Wno-error=implicit-int \
    -Wno-error=implicit-function-declaration \
    -Wno-error=int-conversion \
    -Wno-error=incompatible-pointer-types \
    -Wno-error=return-mismatch" 

  make ARCH=arm CROSS_COMPILE="${TARGET_KERNEL_PREFIX}" mrproper
  make ARCH=arm CROSS_COMPILE="${TARGET_KERNEL_PREFIX}" \
    DEVICE_TREE="${PKG_UBOOT_DEVICE_TREE}" \
    HOSTCC="${HOST_CC}" ${PKG_UBOOT_CONFIG}
  make ARCH=arm CROSS_COMPILE="${TARGET_KERNEL_PREFIX}" \
    DEVICE_TREE="${PKG_UBOOT_DEVICE_TREE}" KCFLAGS="${UBOOT_KCFLAGS}" \
    HOSTCC="${HOST_CC}" u-boot-dtb.bin

  # The SPL loads U-Boot from the SD card's "uboot" GPT partition (see the image
  # step in bootloader/mkimage) as a DHTB image: a 512-byte header (magic +
  # SHA256 + payload length == KEY_INFO_SIZ) followed by the payload. It must
  # stay under CONFIG_UBOOT_MAX_SIZE (1M). Pad to exactly the image size so we
  # don't write sectors past the payload.
  local payload_size dhtb_size
  payload_size=$(stat -c%s u-boot-dtb.bin)
  dhtb_size=$((payload_size + 512))

  if [ ${dhtb_size} -gt $((1024 * 1024)) ]; then
    die "u-boot: DHTB image ${dhtb_size} bytes exceeds the SPL's 1 MiB limit"
  fi

  python3 ${PKG_DIR}/scripts/dhtb_pack.py u-boot-dtb.bin uboot.bin ${dhtb_size}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader

  cp -av ${PKG_BUILD}/uboot.bin ${INSTALL}/usr/share/bootloader
}
