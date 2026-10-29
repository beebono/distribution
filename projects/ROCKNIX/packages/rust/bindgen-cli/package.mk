# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

. ${ROOT}/packages/rust/bindgen-cli/package.mk

# ROCKNIX: Mesa's bindgen rule (used by malisx2) rejects 0.72.0
PKG_VERSION="0.72.1"
PKG_SHA256="4ffb17061b2d71f19c5062d2e17e64107248f484f9775c0b7d30a16a8238dfd1"
PKG_URL="https://github.com/rust-lang/rust-bindgen/archive/refs/tags/v${PKG_VERSION}.tar.gz"
