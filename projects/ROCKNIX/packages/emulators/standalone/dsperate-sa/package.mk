# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="dsperate-sa"
PKG_VERSION="1ccfda1bc0db33d579313882934a86435abe27df"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/beebono/DSperate"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 alsa-lib"
PKG_LONGDESC="A Nintendo DS emulator reimplementing DraStic's JIT and NEON rendering with melonDS accuracy."
PKG_TOOLCHAIN="cmake"

# The SDL frontend is the only thing shipped: no headless frontend, and the
# unit tests are a host-side gate that would only lengthen the target build.
PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                         -DDSPERATE_SDL=ON \
                         -DDSPERATE_HEADLESS=OFF \
                         -DDSPERATE_TESTS=OFF"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/src/frontend/sdl/dsperate ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/*

  mkdir -p ${INSTALL}/usr/config/dsperate
  cp -f ${PKG_DIR}/config/${DEVICE}/dsperate.ini ${INSTALL}/usr/config/dsperate/
}
