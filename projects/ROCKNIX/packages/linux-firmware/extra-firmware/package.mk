# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="extra-firmware"
PKG_VERSION="2b7207cfcb80c53c09dc6e04165789ecaf2d3348"
PKG_LICENSE="proprietary"
PKG_SITE="https://github.com/ROCKNIX/extra-firmware"
PKG_URL="https://github.com/ROCKNIX/extra-firmware/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="extra-firmware: Extra kernel firmware needed for ROCKNIX devices"
PKG_TOOLCHAIN="manual"

if [[ "${DEVICE}" = "T618" ]]; then
  PKG_VERSION="92136aefd83b9a4c1e99ecea3c0a7f82b829019b"
  PKG_SITE="https://github.com/beebono/extra-firmware"
  PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
fi

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_firmware_dir)

  case "${DEVICE}" in
    "SM6115") cp -a SM6115/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8250") cp -a SM8250/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8550") cp -a SM8550/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8650") cp -a SM8650/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8750") cp -a SM8750/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "T618") cp -a T618/* ${INSTALL}/$(get_full_firmware_dir) ;;
  esac
}
