#!/bin/sh
#
# setup.sh -- make build/microcabal/src: MicroCabal's sources
# (ref/MicroCabal, `make ref`) with the Yale Haskell backend added
# (Yale.hs, as MicroCabal.Backend.Yale) and MicroCabal.Main patched to
# offer it as --yale, the default, and MicroCabal.Parse to read more of
# Cabal's syntax (yale-backend.patch), plus mcabal.hs,
# the Main module that runs MicroCabal.Main.  The clone is not changed.
#
#   tools/microcabal/setup.sh       (tools/microcabal/mcabal runs it)

cd "$(dirname "$0")/../.." || exit 1
here=tools/microcabal
src=ref/MicroCabal/src
out=build/microcabal/src
[ -d "$src" ] || { echo "setup.sh: no $src; see doc/plans/MICROCABAL.md" >&2; exit 1; }
rm -rf "$out"
mkdir -p "$out" || exit 1
cp -R "$src/." "$out/" &&
cp "$here/Yale.hs" "$out/MicroCabal/Backend/Yale.hs" &&
cp "$here/mcabal.hs" "$out/mcabal.hs" &&
patch -s -d "$out" -p1 < "$here/yale-backend.patch" ||
  { echo "setup.sh: failed" >&2; exit 1; }
