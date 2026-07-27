# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="rocknix-dpad-mode"
PKG_VERSION=""
PKG_LICENSE="GPLv2"
PKG_SITE="https://rocknix.org"
PKG_DEPENDS_TARGET="toolchain Python3 systemd inputplumber"
PKG_LONGDESC="Toggles the InputPlumber device profile between DPad and analog stick output on a button hold"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/usr/bin/rocknix-dpad-mode ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/rocknix-dpad-mode

  mkdir -p ${INSTALL}/usr/lib/systemd/system
  cp ${PKG_DIR}/sources/usr/lib/systemd/system/rocknix-dpad-mode.service \
    ${INSTALL}/usr/lib/systemd/system
}

post_install() {
  enable_service rocknix-dpad-mode.service
}
