#!/bin/sh
# Builds Helium 1.8.1 (https://hackage.haskell.org/package/helium) with Yale
# Haskell, and its LVM runtime lvmrun 1.0 with the C compiler:
#   1. helium, lvmlib and Top, which Stackage (MicroCabal's package list)
#      does not have, fetched from Hackage into build/mcabal/local and
#      installed with MicroCabal (their patches: tools/microcabal/patches);
#   2. lvmrun (build-type Make, C), configured for clang (its feature
#      tests are K&R C) and patched for a 64-bit macOS (lvmrun.patch).
# Then, with build/mcabal/bin on PATH (helium runs coreasm):
#   helium Hello.hs && LVMPATH=.:$lib lvmrun Hello
# where lib is build/mcabal/yale-<version>/packages/helium-1.8.1/data/lib,
# Helium's own Prelude (compiled to .lvm by the first helium run).
set -e
top=$(cd "$(dirname "$0")/../../.." && pwd)
CABALDIR=${CABALDIR:-$top/build/mcabal}
export CABALDIR
local=$CABALDIR/local
mkdir -p "$local"
fetch() {
  [ -d "$local/$1" ] && return
  curl -sL -o "$local/$1.tar.gz" "https://hackage.haskell.org/package/$1/$1.tar.gz"
  (cd "$local" && tar xzf "$1.tar.gz")
}
for p in lvmlib-1.1 Top-1.7 helium-1.8.1; do
  fetch $p
  (cd "$local/$p" && nice -n 19 "$top/tools/microcabal/mcabal" -r install)
done

fetch lvmrun-1.0
cd "$local/lvmrun-1.0"
if [ ! -f .yale-patched ]; then
  patch -p1 < "$top/tools/conformance/helium/lvmrun.patch"
  touch .yale-patched
fi
cc="cc -Wno-error=implicit-int -Wno-error=implicit-function-declaration"
cc="$cc -Wno-error=int-conversion -Wno-error=incompatible-pointer-types"
cc="$cc -Wno-error=incompatible-function-pointer-types"
nice -n 19 ./configure "-cc=$cc"
nice -n 19 make
cp lvmrun "$CABALDIR/bin/"
