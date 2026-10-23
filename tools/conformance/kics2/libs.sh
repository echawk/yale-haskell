#!/bin/sh
# Compiles KiCS2's Curry library for Yale Haskell (doc/plans/KICS2.md,
# step 5), after setup.sh and once the Yale-built kics2c
# (build/kics2/kics2c/kics2c) and curry-frontend (build/mcabal/bin) exist:
#   1. the library's 29 modules, copied to build/kics2/lib/lib, compiled
#      to Haskell by the Yale-built kics2c with the Yale-built frontend
#      (kics2c finds its library only in a directory named lib);
#   2. that Haskell installed as the package kics2-libs, so a Curry
#      program compiles only its own modules (run-curry.sh).
# $YALE is the yale-haskell that builds the package; the Prelude's 2.6 MB
# of Haskell needs a 16 GB heap (make HEAP_MB=16384).
set -e
top=$(cd "$(dirname "$0")/../../.." && pwd)
dist=$top/ref/kics2-dist/kics2-3.5.0-arm64-darwin
kics2c=$top/build/kics2/kics2c/kics2c
lib=$top/build/kics2/lib
pkg=$top/build/kics2/libs
home=${TMPDIR:-/tmp}/kics2-home.$$
CABALDIR=${CABALDIR:-$top/build/mcabal}
export CABALDIR

# 1. the library's Haskell
rm -rf "$lib"
mkdir -p "$lib/lib" "$lib/bin" "$home"
(cd "$dist/lib" && find . -type f \( -name '*.curry' -o -name '*.kics2.hs' \) |
 cpio -pdm "$lib/lib" 2>/dev/null)
ln -sf "$top/build/mcabal/bin/curry-frontend" "$lib/bin/kics2-frontend"
mods=$(cd "$lib/lib" && find . -name '*.curry' | sed 's|^\./||; s|\.curry$||; s|/|.|g' | sort)
for m in $mods; do
  (cd "$lib" && HOME=$home "$kics2c" -v1 -i lib "$m")
done
rm -rf "$home"

# 2. the package
rm -rf "$pkg"
mkdir -p "$pkg"
out=$lib/lib/.curry/kics2-3.5.0
(cd "$out" && find . -name 'Curry_*.hs' | cpio -pdm "$pkg" 2>/dev/null)
exposed=$(cd "$pkg" && find . -name 'Curry_*.hs' | sed 's|^\./||; s|\.hs$||; s|/|.|g' | sort | sed '2,$s/^/    , /; 1s/^/      /')
cat > "$pkg/kics2-libs.cabal" <<CABAL
name:           kics2-libs
version:        3.5.0
description:    KiCS2's Curry library, compiled to Haskell by KiCS2
license:        OtherLicense
author:         The KiCS2 Team
build-type:     Simple
cabal-version:  >= 1.10

library
  build-depends: base, containers, mtl, directory, process, time, kics2-runtime
  exposed-modules:
$exposed
  hs-source-dirs: .
  default-language: Haskell2010
  cpp-options: -D__GLASGOW_HASKELL__=908
CABAL
(cd "$pkg" && "$top/tools/microcabal/mcabal" -r install)
echo "installed: kics2-libs ($pkg)"
