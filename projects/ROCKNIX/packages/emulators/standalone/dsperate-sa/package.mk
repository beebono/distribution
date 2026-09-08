# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="dsperate-sa"
PKG_VERSION="1.12.0"
PKG_SHA256="7cda34d4be766d7f855a1f5d71d9f3c3b60a433f124b048d19e19b412aefb0aa"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/beebono/DSperate"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="A Nintendo DS emulator reimplementing DraStic's JIT and NEON rendering with melonDS accuracy."
PKG_TOOLCHAIN="manual"

# Upstream CI ships a dynamically linked, PGO-built aarch64 binary (it only
# needs SDL2, libstdc++ and glibc from the image). The committed PGO profile
# is tied to the compiler that made it, so a local build with the ROCKNIX
# toolchain can not apply it due to the compiler version mismatch.
PKG_URL="${PKG_SITE}/releases/download/v${PKG_VERSION}/dsperate-v${PKG_VERSION}-linux-${TARGET_ARCH}.tar.gz"
PKG_SOURCE_DIR="dsperate-v${PKG_VERSION}-linux-${TARGET_ARCH}"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/dsperate ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/*

  mkdir -p ${INSTALL}/usr/config/dsperate
  cp -f ${PKG_DIR}/config/${DEVICE}/dsperate.ini ${INSTALL}/usr/config/dsperate/
}
