#!/bin/sh
# Rebuild the kernel of this release from this directory alone: the public base (BASE.env), the patches in
# `series` order, the board device trees, the firmware CONFIG_EXTRA_FIRMWARE builds in, and the .config.
#   sh build.sh [WORKDIR]        (default ./work; needs git, make, an aarch64-linux-gnu- cross gcc, bc, flex,
#                                 bison, libssl-dev, and the toolchain named in BASE.env for an identical Image)
# Out: WORKDIR/kbuild-6.12-dho900/arch/arm64/boot/Image, .../dts/rockchip/rk3399-rigol-{dho900,mho900}.dtb, the modules
# (WORKDIR/modroot after `modules_install`, plus the out-of-tree ones in ../modules).
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
W="${1:-$HERE/work}"
. "$HERE/BASE.env"
CROSS="${CROSS_COMPILE:-aarch64-linux-gnu-}"
JOBS="${JOBS:-$(nproc)}"
mkdir -p "$W"
# the release build's own directory names, with the same map: the binaries do not depend on where they are built
K="$W/kernel-6.12"; O="$W/kbuild-6.12-dho900"
export KCFLAGS="-ffile-prefix-map=$W/=" KAFLAGS="-ffile-prefix-map=$W/="
if [ ! -d "$K/.git" ]; then
    git init -q "$K"; git -C "$K" remote add origin "$KERNEL_REPO"
fi
git -C "$K" fetch -q --depth 1 origin "$KERNEL_COMMIT"
git -C "$K" checkout -q -f --detach FETCH_HEAD
git -C "$K" clean -qfdx
while read -r p; do
    [ -n "$p" ] || continue
    git -C "$K" apply "$HERE/patches/$p"
done < "$HERE/series"
cp "$HERE"/dts/*.dts "$K/arch/arm64/boot/dts/rockchip/"
for d in "$HERE"/dts/*.dts; do
    printf 'dtb-$(CONFIG_ARCH_ROCKCHIP) += %s.dtb\n' "$(basename "$d" .dts)" >> "$K/arch/arm64/boot/dts/rockchip/Makefile"
done
mkdir -p "$K/nova-firmware"; cp "$HERE"/firmware/regulatory.db* "$K/nova-firmware/"
rm -rf "$O"; mkdir -p "$O"; cp "$HERE/config" "$O/.config"
export KBUILD_BUILD_TIMESTAMP KBUILD_BUILD_USER KBUILD_BUILD_HOST KBUILD_BUILD_VERSION SOURCE_DATE_EPOCH
make -C "$K" O="$O" ARCH=arm64 CROSS_COMPILE="$CROSS" olddefconfig
cmp -s "$HERE/config" "$O/.config" || echo "note: olddefconfig changed the .config (another toolchain?)" >&2
make -C "$K" O="$O" ARCH=arm64 CROSS_COMPILE="$CROSS" -j"$JOBS" Image dtbs modules
rm -rf "$W/modroot"
make -C "$K" O="$O" ARCH=arm64 CROSS_COMPILE="$CROSS" INSTALL_MOD_PATH="$W/modroot" INSTALL_MOD_STRIP=1 modules_install
sh "$HERE/../modules/build.sh" "$O" "$W"
echo "built $(cat "$O/include/config/kernel.release") in $W"
