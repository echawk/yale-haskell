#!/bin/sh
# Stages KiCS2 3.5.0 for Yale Haskell (doc/plans/KICS2.md):
#   1. the KiCS2 distribution (arm64 macOS, from
#      https://www.curry-lang.org/kics2/download.html) in
#      ref/kics2-dist/kics2-3.5.0-arm64-darwin, its lib/ filled from
#      lib-trunk/src;
#   2. the compiler's Haskell, generated there by the distribution's kics2c
#      (no GHC needed; HOME is redirected because kics2c writes ~/.kics2rc);
#   3. the runtime as the package build/kics2/runtime (kics2-runtime), with
#      the IORef IDSupply and Installation.hs as KiCS2's make writes it.
#   4. tree-monad and parallel-tree-search, which Stackage (MicroCabal's
#      package list) does not have, fetched from Hackage and installed.
# Then: (cd build/kics2/runtime && tools/microcabal/mcabal -r install).
set -e
top=$(cd "$(dirname "$0")/../../.." && pwd)
dist=$top/ref/kics2-dist/kics2-3.5.0-arm64-darwin
tarball=$top/ref/kics2-dist/kics2-3.5.0-arm64-darwin.tar.gz
if [ ! -d "$dist" ]; then
  mkdir -p "$top/ref/kics2-dist"
  [ -f "$tarball" ] || curl -sL -o "$tarball" https://www.curry-lang.org/kics2/download/kics2-3.5.0-arm64-darwin.tar.gz
  (cd "$top/ref/kics2-dist" && tar xzf "$tarball")
fi
cd "$dist"
[ -f lib/Prelude.curry ] || cp -R lib-trunk/src/. lib/

# 2. the compiler's Haskell
home=${TMPDIR:-/tmp}/kics2-home.$$
mkdir -p "$home"
(cd src && ln -sf ../bin bin && ln -sf ../lib lib &&
 HOME=$home ../bin/.local/kics2c -v1 \
   -i ".:../lib:$(ls -d ../.cpm/packages/*/src | tr '\n' ':' | sed 's/:$//')" \
   KiCS2.Compile)
rm -rf "$home"

# 3. the runtime package
rt=$top/build/kics2/runtime
mkdir -p "$rt"
cp runtime/*.hs runtime/ID.hs-boot runtime/idsupplyioref/IDSupply.hs "$rt/"
rm -f "$rt/Setup.hs"
{ cat src/Installation.curry; echo
  echo 'installDir :: String'
  echo 'installDir = if null pkgInstallDir then buildDir else if unsafePerformIO (doesDirectoryExist pkgInstallDir) then pkgInstallDir else buildDir'
  echo; echo 'buildDir :: String'; echo "buildDir = \"$dist\""
  echo; echo 'pkgInstallDir :: String'; echo 'pkgInstallDir = ""'
} > "$rt/Installation.hs"
cat > "$rt/kics2-runtime.cabal" <<'CABAL'
name:           kics2-runtime
version:        3.5.0
description:    The runtime environment for KiCS2
license:        OtherLicense
author:         The KiCS2 Team
build-type:     Simple
cabal-version:  >= 1.10

library
  build-depends: base, containers, mtl, parallel-tree-search, tree-monad, directory
  exposed-modules:
      Basics, CurryException, KiCS2Debug, FailInfo
    , FailTrace, IDSupply, Installation
    , MonadList, MonadSearch, PrimTypes, SafeExec
  other-modules:
      ConstStore, ID, Search, Solver
    , Strategies, Types
  hs-source-dirs: .
  default-language: Haskell2010
  cpp-options: -D__GLASGOW_HASKELL__=908
CABAL
# 4. the runtime's Hackage dependencies outside Stackage
CABALDIR=${CABALDIR:-$top/build/mcabal}
export CABALDIR
local=$CABALDIR/local
mkdir -p "$local"
for p in tree-monad-0.3.2 parallel-tree-search-0.4.2; do
  if [ ! -d "$local/$p" ]; then
    curl -sL -o "$local/$p.tar.gz" "https://hackage.haskell.org/package/$p/$p.tar.gz"
    (cd "$local" && tar xzf "$p.tar.gz")
  fi
  (cd "$local/$p" && "$top/tools/microcabal/mcabal" -r install)
done
echo "staged: $rt"
