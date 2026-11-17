# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="avbtool"
PKG_VERSION="3328b7b60ae384e1a92f44d7e6f3ac021c2b05be"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://android.googlesource.com/platform/external/avb"
PKG_URL="${PKG_SITE}.git"
PKG_LONGDESC="avbtool: Android Verified Boot image tool, with the public AOSP test keys"
PKG_TOOLCHAIN="manual"
PKG_DEPENDS_HOST="toolchain Python3:host openssl:host"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/avbtool
    cp -a avbtool.py ${TOOLCHAIN}/avbtool
    cp -a test/data/testkey_rsa2048.pem ${TOOLCHAIN}/avbtool
}
