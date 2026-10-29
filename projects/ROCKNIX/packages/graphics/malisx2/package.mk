# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="malisx2"
PKG_VERSION="c8d18effb1867aecd47bc98e93b11a31db4b1e3c"
PKG_SHA256="b559568a61054533338436efb0b5e5a125d54f6d33f3967de8caf54a1d2fedbb"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/bmdhacks/malisx2"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain rust:host bindgen-cli:host Mako:host pyyaml:host libdrm systemd mesa"
PKG_DEPENDS_UNPACK="malisx2-mesa"
PKG_LONGDESC="Vulkan driver for Arm Mali on the kbase kernel driver (Mali-G52), loaded by ARMSX2 and Azahar."
PKG_TOOLCHAIN="meson"

# Installed separately, not over the system driver. The emulators' start scripts
# point the Vulkan loader at this ICD for their process only.
MALISX2_DIR="/usr/share/malisx2"

pre_configure_target() {
  ln -sfn $(get_build_dir malisx2-mesa) ${PKG_BUILD}/mesa

  # The generated cross file names rustc without a target; meson downloads the
  # Rust crates kraid needs (subprojects/) during setup.
  export LIBCLANG_PATH="${TOOLCHAIN}/lib"
  cat >${PKG_BUILD}/.${TARGET_NAME}/rust-cross.conf <<CONF
[binaries]
rust = ['${TOOLCHAIN}/bin/rustc', '--target', '${TARGET_NAME}', '-C', 'linker=${TARGET_CC}']

[properties]
bindgen_clang_arguments = ['--sysroot=${SYSROOT_PREFIX}']
CONF
  PKG_MESON_OPTS_TARGET="--cross-file=${PKG_BUILD}/.${TARGET_NAME}/rust-cross.conf"
}

makeinstall_target() {
  mkdir -p ${INSTALL}${MALISX2_DIR}
    cp -a ${PKG_BUILD}/.${TARGET_NAME}/src/libvulkan_malisx2.so ${INSTALL}${MALISX2_DIR}

  ICD_API_VERSION=$(sed -n 's/.*"api_version": *"\([^"]*\)".*/\1/p' ${PKG_BUILD}/mali_icd.json.in)
  cat >${INSTALL}${MALISX2_DIR}/malisx2_icd.aarch64.json <<ICD
{
    "ICD": {
        "api_version": "${ICD_API_VERSION}",
        "library_arch": "64",
        "library_path": "${MALISX2_DIR}/libvulkan_malisx2.so"
    },
    "file_format_version": "1.0.1"
}
ICD
}
