NovaOS r96 -- Linux kernel source
==================================================

Copyright (C) 2026 Olympian LED, Inc.

Linux and the other programs below are free software under their own licenses (GPL-2.0, LGPL and
others: each package names its own); our changes to them are under the same license as the file they
change.

This directory is the complete corresponding source of the Linux kernel 6.12.114+ of NovaOS r96 and its kernel modules:

  linux/    the Linux kernel 6.12.114+: the public base (BASE.env), our 30 patches in series order,
            the complete .config, the board device trees, and build.sh, which rebuilds the Image, the
            device trees and the modules from exactly these.
  modules/  the out-of-tree kernel modules: Xilinx's XDMA driver at its public commit with our patch,
            and the rtw89 USB Wi-Fi driver at its public commit; build.sh builds them against linux/'s
            output.

WRITTEN OFFER. For three years from the date you received this release, Olympian LED, Inc. will give anyone
a copy of this source on a physical medium for no more than the cost of making and sending it.
Write to Olympian LED, Inc., brady@aioscilloscope.com, naming the release (r96).

NovaOS's own programs are not copyleft and are not part of this source.
