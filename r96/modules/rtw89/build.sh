#!/usr/bin/env bash
# Build the rtw89 USB Wi-Fi modules (rtw89-pin.env) out of tree against a kernel build directory:
#   build.sh KDIR OUTDIR ARCH CROSS_COMPILE
# It fetches the pinned source, pins GIT_COMMIT in its Makefile, leaves the multicolour-LED part out when the kernel
# has no CONFIG_LEDS_CLASS_MULTICOLOR, builds with the build directory mapped away (-ffile-prefix-map) and copies the
# modules RTW89_MODULES names to OUTDIR.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$#" -eq 4 ] || { echo "usage: $0 KDIR OUTDIR ARCH CROSS_COMPILE" >&2; exit 2; }
KDIR="$1"; OUT="$2"; ARCH="$3"; CROSS="$4"
. "$HERE/rtw89-pin.env"
[ -f "$KDIR/Module.symvers" ] || { echo "FATAL: $KDIR has no Module.symvers -- build the kernel first" >&2; exit 1; }
for sym in CONFIG_CFG80211 CONFIG_MAC80211 CONFIG_USB; do
    grep -Eq "^${sym}=(y|m)$" "$KDIR/.config" || { echo "FATAL: $KDIR/.config lacks ${sym}=y|m (rtw89 needs it)" >&2; exit 1; }
done
SRC="${NOVA_RTW89_SRC:-$(dirname "$KDIR")/rtw89-src}"
if [ ! -d "$SRC/.git" ]; then
    git init -q "$SRC"
    git -C "$SRC" remote add origin "$RTW89_REPO"
fi
if [ "$(git -C "$SRC" rev-parse -q --verify 'HEAD^{commit}' 2>/dev/null || :)" != "$RTW89_COMMIT" ]; then
    git -C "$SRC" fetch -q --depth 1 origin "$RTW89_COMMIT"
    git -C "$SRC" checkout -q -f --detach FETCH_HEAD
fi
[ "$(git -C "$SRC" rev-parse HEAD)" = "$RTW89_COMMIT" ] || { echo "FATAL: $SRC is not at $RTW89_COMMIT" >&2; exit 1; }
[ -z "$(git -C "$SRC" status --porcelain)" ] || { echo "FATAL: $SRC has local changes; it must stay the pinned tree" >&2; exit 1; }

B="$(dirname "$KDIR")/rtw89-build-$(basename "$KDIR")"
rm -rf "$B"; mkdir -p "$B"
git -C "$SRC" archive HEAD -- ':!firmware' ':!fedora' ':!hostapd' | tar -x -C "$B"
grep -q '^ccflags-y += -DGIT_COMMIT=$(shell git' "$B/Makefile" || { echo "FATAL: rtw89 Makefile no longer derives GIT_COMMIT from git; re-check build.sh" >&2; exit 1; }
sed -i "s|^ccflags-y += -DGIT_COMMIT=.*\$|ccflags-y += -DGIT_COMMIT=$RTW89_COMMIT|" "$B/Makefile"
grep -qx "ccflags-y += -DGIT_COMMIT=$RTW89_COMMIT" "$B/Makefile" || { echo "FATAL: GIT_COMMIT not pinned in $B/Makefile" >&2; exit 1; }
grep -Eq '^CONFIG_LEDS_CLASS=(y|m)$' "$KDIR/.config" || { echo "FATAL: $KDIR/.config lacks CONFIG_LEDS_CLASS (rtw89's led.c needs it)" >&2; exit 1; }
if ! grep -Eq '^CONFIG_LEDS_CLASS_MULTICOLOR=(y|m)$' "$KDIR/.config"; then
    grep -Eq '^[[:space:]]+led_mc[.]o$' "$B/Makefile" && grep -q -- '-DCONFIG_RTW89_LEDS_MC' "$B/Makefile" ||
        { echo "FATAL: rtw89 Makefile's led_mc lines changed; re-check build.sh" >&2; exit 1; }
    sed -i -e 's/^[[:space:]]*led_mc[.]o$//' -e 's/ -DCONFIG_RTW89_LEDS_MC//' "$B/Makefile"
    ! grep -Eq 'led_mc[.]o|RTW89_LEDS_MC' "$B/Makefile" || { echo "FATAL: led_mc is still in $B/Makefile" >&2; exit 1; }
    echo "rtw89: no CONFIG_LEDS_CLASS_MULTICOLOR in this kernel; built without led_mc"
fi
make -C "$KDIR" M="$B" ARCH="$ARCH" CROSS_COMPILE="$CROSS" \
     KCFLAGS="${KCFLAGS:-} -ffile-prefix-map=$B/= -Wno-missing-prototypes -Wno-missing-declarations" \
     -j"${NOVA_JOBS:-$(nproc)}" modules
mkdir -p "$OUT"
for m in $RTW89_MODULES; do
    [ -f "$B/$m.ko" ] || { echo "FATAL: $m.ko was not built" >&2; exit 1; }
    cp "$B/$m.ko" "$OUT/"
done
echo "rtw89 $RTW89_COMMIT: $(cd "$OUT" && ls rtw89_*.ko | tr '\n' ' ')"
