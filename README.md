# NovaOS kernel source

The Linux kernel source of NovaOS releases, published under the GNU General Public License, version 2.

Each release is a tag here with a GitHub Release attached. A release holds one archive, the complete corresponding
source of the kernel that release ships, together with its SHA-256 sum:

| Release | Kernel | Boards | Archive |
|---|---|---|---|
| r96 | Linux 6.12.114 (Rockchip 6.12 BSP + kernel.org 6.12 stable), 30 patches | RK3399: DHO800 / DHO900, MHO900 | `linux-rk3399-scope-r96.tar.xz` |

## What an archive contains

- `linux/BASE.env` names the public base tree and its exact commit:
  [Bradyok/linux-rockchip](https://github.com/Bradyok/linux-rockchip), Rockchip's develop-6.12 BSP with
  kernel.org's 6.12 stable releases merged in. The commit is tagged there for every release that uses it.
- `linux/patches/` and `linux/series` hold our patches to that tree, in the order they apply.
- `linux/config` is the complete kernel configuration.
- `linux/dts/` holds the board device trees. `linux/firmware/` holds the firmware the kernel builds in.
- `linux/build.sh` rebuilds the kernel image, the device tree blobs and the in-tree modules from these files.
- `modules/` holds the out-of-tree drivers the release builds: the public commits they come from, our patches to
  them, and `modules/build.sh`.
- `README.txt` (the written offer), `SHA256SUMS` and `bundle.json` (the inventory).

Every release's archive is checked before it is published: a kernel built from the archive alone matches the
release's own image, device trees and modules byte for byte.

## Building

On a Linux host with git, make, bc, flex, bison, the OpenSSL headers and an `aarch64-linux-gnu-` cross compiler
(the exact toolchain an identical image needs is named in `linux/BASE.env`):

    tar -xJf linux-rk3399-scope-r96.tar.xz
    sh linux-rk3399-scope-r96/linux/build.sh /path/to/workdir

It fetches the base commit, applies the patches, builds the image, the device tree blobs and the modules, and then
the out-of-tree modules (`modules/build.sh`).

## Licence and credit

The Linux kernel is licensed under GPL-2.0. Our patches to it are under the licence of the files they change. Our
board device trees are dual-licensed `GPL-2.0+ OR MIT`.

Copyright (C) 2026 Olympian LED, Inc. for the patches and the files they create. Keep these notices when you
redistribute them.

## Written offer

For three years from the date you received a NovaOS release, Olympian LED, Inc. will give anyone a copy of that
release's kernel source on a physical medium for no more than the cost of making and sending it. Write to
Olympian LED, Inc., brady@aioscilloscope.com, naming the release.
