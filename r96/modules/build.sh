#!/bin/sh
# The out-of-tree modules, against a kernel build directory made by ../linux/build.sh:
#   sh build.sh KBUILD_OUT WORKDIR
# Built in WORKDIR/<name>-build with WORKDIR mapped away (-ffile-prefix-map), as the release built them, so a
# module's file names do not depend on the directory it was built in.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
O="$1"; W="$2"
CROSS="${CROSS_COMPILE:-aarch64-linux-gnu-}"
. "$HERE/xdma/PIN.env"
X="$W/dma_ip_drivers"
if [ ! -d "$X/.git" ]; then git init -q "$X"; git -C "$X" remote add origin "$XDMA_REPO"; fi
git -C "$X" fetch -q --depth 1 origin "$XDMA_COMMIT"
git -C "$X" checkout -q -f --detach FETCH_HEAD
rm -rf "$W/xdma-build"; mkdir -p "$W/xdma-build"
cp -r "$X/$XDMA_SUBDIR/xdma" "$X/$XDMA_SUBDIR/include" "$W/xdma-build/"
for p in "$HERE"/xdma/*.patch; do patch -d "$W/xdma-build" -p1 --no-backup-if-mismatch < "$p"; done
make -C "$O" ARCH=arm64 CROSS_COMPILE="$CROSS" M="$W/xdma-build/xdma" KCFLAGS="-ffile-prefix-map=$W/=" modules
make -C "$O" ARCH=arm64 CROSS_COMPILE="$CROSS" M="$W/xdma-build/xdma" INSTALL_MOD_PATH="$W/modroot" INSTALL_MOD_STRIP=1 modules_install
# rtw89 (USB Wi-Fi), fetched at its pin by its own build script, built in WORKDIR/rtw89-build-<kbuild dir>
NOVA_RTW89_SRC="$W/rtw89-src" bash "$HERE/rtw89/build.sh" "$O" "$W/rtw89-out" arm64 "$CROSS"
make -C "$O" ARCH=arm64 CROSS_COMPILE="$CROSS" M="$W/rtw89-build-$(basename "$O")" INSTALL_MOD_PATH="$W/modroot" INSTALL_MOD_STRIP=1 modules_install
