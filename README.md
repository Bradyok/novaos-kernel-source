# NovaOS kernel source

The Linux kernel source of NovaOS releases, published under the GNU General Public License, version 2.

Each release is a tag here with a GitHub Release attached:

| Release | Kernel | Boards | Complete source |
|---|---|---|---|
| [r136](https://github.com/Bradyok/novaos-kernel-source/releases/tag/r136) (also r137's kernel) | Linux 6.12.115 (Rockchip 6.12 BSP + kernel.org 6.12 stable), 32 patches | RK3399: DHO800 / DHO900, MHO900 | `linux-6.12.115-novaos-r136.tar.xz` |
| [r119](https://github.com/Bradyok/novaos-kernel-source/releases/tag/r119) | Linux 6.12.114 (Rockchip 6.12 BSP + kernel.org 6.12 stable), 32 patches | RK3399: DHO800 / DHO900, MHO900 | `linux-6.12.114-novaos-r119.tar.xz` |
| [r96](https://github.com/Bradyok/novaos-kernel-source/releases/tag/r96) | Linux 6.12.114 (Rockchip 6.12 BSP + kernel.org 6.12 stable), 30 patches | RK3399: DHO800 / DHO900, MHO900 | `linux-6.12.114-novaos-r96.tar.xz` |

## The downloads

**The complete source tree** (`linux-<version>-novaos-<release>.tar.xz`) is what to download. It holds:

- `linux/`: the kernel, with every patch, board device tree and built-in firmware applied;
- `novaos-<release>.config`: its configuration;
- `xdma/` and `rtw89/`: the out-of-tree drivers the release builds, as built;
- `build.sh`: builds the kernel image, the device tree blobs and every module from the archive alone, with no
  network, and fails if either of the two modules below is missing;
- `README.txt`: the written offer.

**The patch set** (`linux-rk3399-scope-<release>.tar.xz`, also readable here under `<release>/`) is the same
release as our changes only: the patches in the order they apply, the configuration, the device trees and the
build scripts, and (from r136) `install/`, which puts a kernel you built into the release's boot image. Its
`linux/build.sh` downloads the base tree, [Bradyok/linux-rockchip](https://github.com/Bradyok/linux-rockchip) at the
commit `linux/BASE.env` names (tagged there for every release that uses it), and applies them.

Every release is checked before it is published. A build from either archive alone matches the release's own
kernel image, device trees and modules byte for byte. The complete tree is also built in a fresh directory with
every network tool disabled.

## The boot loaders

The source of the boot loaders NovaOS builds for the same scopes (mainline U-Boot with our patches, and
Trusted Firmware-A) is in [Bradyok/novaos-boot-source](https://github.com/Bradyok/novaos-boot-source).

## Building

On a Linux host with make, bc, flex, bison, the OpenSSL headers and an `aarch64-linux-gnu-` cross compiler:

    tar -xJf linux-6.12.115-novaos-r136.tar.xz
    sh linux-6.12.115-novaos-r136/build.sh /path/to/workdir

`BUILDING.txt` in the archive names the toolchain that gives byte-identical output.

### What the build makes, and where

The build is out of tree: nothing is written into the unpacked `linux/`. In the work directory:

| What | Where |
|---|---|
| The kernel image | `kbuild-6.12-dho900/arch/arm64/boot/Image` |
| The device tree blobs | `kbuild-6.12-dho900/arch/arm64/boot/dts/rockchip/rk3399-rigol-dho900.dtb`, `rk3399-rigol-mho900.dtb` |
| Every module, installed (r136: 380) | `modroot/lib/modules/<kernel release>/` (`6.12.115+` for r136), the out-of-tree drivers in its `updates/` |

Two of the modules carry the scope's acquisition data, and both must stay modules:

- `kernel/drivers/pci/controller/pcierockchiphost.ko`: the RK3399 PCIe host (`CONFIG_PCIE_ROCKCHIP_HOST=m`). Its
  sources are `pcie-rockchip-host.c` and `pcie-rockchip.c`, which kbuild links into one module named
  `pcierockchiphost`, so no build makes a `pcie-rockchip-host.ko`. The host trains the PCIe link once, when it
  probes, and the link to the acquisition FPGA trains only after the FPGA has booted its acquisition image. Built
  into the kernel (Rockchip's `rockchip_linux_defconfig` has it `=y`), it probes at boot, before the FPGA is up,
  and the link fails. Build with the release's own `.config`.
- `updates/xdma.ko`: Xilinx's XDMA driver with our patch, built by the same `build.sh`.

NovaOS loads `pcierockchiphost`, and then `xdma` with `poll_mode=1`, by name once the FPGA has booted, from its
own FPGA service, which is not part of this source. Its `/etc/modprobe.d/nova-dho900.conf` blacklists both, so
udev does not load either one early by its alias. On another root file system with udev, blacklist both the same way.

## License and credit

The Linux kernel is licensed under GPL-2.0. Our patches to it are under the license of the files they change. Our
board device trees are dual-licensed `GPL-2.0+ OR MIT`.

Copyright (C) 2026 Olympian LED, Inc. for the patches and the files they create. Keep these notices when you
redistribute them.

## Written offer

For three years from the date you received a NovaOS release, Olympian LED, Inc. will give anyone a copy of that
release's kernel source on a physical medium for no more than the cost of making and sending it. Write to
Olympian LED, Inc., brady@aioscilloscope.com, naming the release.
