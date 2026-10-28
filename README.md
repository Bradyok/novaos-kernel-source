# NovaOS kernel source

The Linux kernel source of NovaOS releases, published under the GNU General Public License, version 2.

Each release is a tag here with a GitHub Release attached:

| Release | Kernel | Boards | Complete source |
|---|---|---|---|
| [r96](https://github.com/Bradyok/novaos-kernel-source/releases/tag/r96) | Linux 6.12.114 (Rockchip 6.12 BSP + kernel.org 6.12 stable), 30 patches | RK3399: DHO800 / DHO900, MHO900 | `linux-6.12.114-novaos-r96.tar.xz` |

## The downloads

**The complete source tree** (`linux-<version>-novaos-<release>.tar.xz`) is what to download. It holds:

- `linux/`: the kernel, with every patch, board device tree and built-in firmware applied;
- `novaos-<release>.config`: its configuration;
- `xdma/` and `rtw89/`: the out-of-tree drivers the release builds, as built;
- `build.sh`: builds the kernel image, the device tree blobs and every module from the archive alone, with no
  network;
- `README.txt`: the written offer.

**The patch set** (`linux-rk3399-scope-<release>.tar.xz`, also readable here under `<release>/`) is the same
release as our changes only: the patches in the order they apply, the configuration, the device trees and the
build scripts. Its `linux/build.sh` downloads the base tree,
[Bradyok/linux-rockchip](https://github.com/Bradyok/linux-rockchip) at the commit `linux/BASE.env` names (tagged
there for every release that uses it), and applies them.

Every release is checked before it is published. A build from either archive alone matches the release's own
kernel image, device trees and modules byte for byte. The complete tree is also built in a fresh directory with
every network tool disabled.

## The boot loaders

The source of the boot loaders NovaOS builds for the same scopes (mainline U-Boot with our patches, and
Trusted Firmware-A) is in [Bradyok/novaos-boot-source](https://github.com/Bradyok/novaos-boot-source).

## Building

On a Linux host with make, bc, flex, bison, the OpenSSL headers and an `aarch64-linux-gnu-` cross compiler:

    tar -xJf linux-6.12.114-novaos-r96.tar.xz
    sh linux-6.12.114-novaos-r96/build.sh /path/to/workdir

`BUILDING.txt` in the archive names the toolchain that gives byte-identical output.

## License and credit

The Linux kernel is licensed under GPL-2.0. Our patches to it are under the license of the files they change. Our
board device trees are dual-licensed `GPL-2.0+ OR MIT`.

Copyright (C) 2026 Olympian LED, Inc. for the patches and the files they create. Keep these notices when you
redistribute them.

## Written offer

For three years from the date you received a NovaOS release, Olympian LED, Inc. will give anyone a copy of that
release's kernel source on a physical medium for no more than the cost of making and sending it. Write to
Olympian LED, Inc., brady@aioscilloscope.com, naming the release.
