#!/bin/sh
# Rebuild the kernel of this release from this directory alone: the public base (BASE.env), the patches in
# `series` order, the board device trees, the firmware CONFIG_EXTRA_FIRMWARE builds in, and the .config.
#   sh build.sh [WORKDIR]        (default ./work; needs git, make, an aarch64-linux-gnu- cross gcc, bc, flex,
#                                 bison, libssl-dev, and the toolchain named in BASE.env for an identical Image)
# Out: WORKDIR/kbuild-6.12-dho900/arch/arm64/boot/Image, .../dts/rockchip/rk3399-rigol-{dho900,mho900}.dtb, every
# module installed under WORKDIR/modroot/lib/modules/<kernel release>/ (the out-of-tree ones from ../modules in updates/).
# The scope's acquisition path needs two of them; build.sh fails when either is missing and prints where they are:
# kernel/drivers/pci/controller/pcierockchiphost.ko, the RK3399 PCIe host (kbuild links pcie-rockchip-host.c and
# pcie-rockchip.c into this one module; there is no pcie-rockchip-host.ko), and updates/xdma.ko. The host must stay a
# module (CONFIG_PCIE_ROCKCHIP_HOST=m): it trains the link once, at probe, and the FPGA's link trains only after the
# FPGA has booted, so it is loaded then, by name. Built in, it would probe at boot and the link would fail.
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
# the public tree over the network: a reset connection (GitHub dropped one mid-download on 2026-10-28) is tried again
n=0; until git -C "$K" fetch -q --depth 1 origin "$KERNEL_COMMIT"; do
    n=$((n + 1)); [ "$n" -lt 4 ] || { echo "fail: fetching $KERNEL_COMMIT from $KERNEL_REPO, 4 tries" >&2; exit 1; }
    echo "fetch of $KERNEL_COMMIT failed; again in $((n * 15)) s" >&2; sleep $((n * 15))
done
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
NEED=kernel/drivers/pci/controller/pcierockchiphost.ko
sh "$HERE/../modules/build.sh" "$O" "$W"
NEED="$NEED updates/xdma.ko"
KREL="$(cat "$O/include/config/kernel.release")"; MODS="$W/modroot/lib/modules/$KREL"
grep -qx 'CONFIG_PCIE_ROCKCHIP_HOST=m' "$O/.config" || {
    echo "fail: CONFIG_PCIE_ROCKCHIP_HOST is not =m in $O/.config: the PCIe host must be a module (see the top)" >&2; exit 1; }
for m in $NEED; do
    [ -f "$MODS/$m" ] || { echo "fail: $m is not in $MODS" >&2; exit 1; }
    echo "module: $MODS/$m"
done
echo "built $KREL in $W: $(find "$MODS" -name '*.ko' | wc -l) modules in $MODS"
