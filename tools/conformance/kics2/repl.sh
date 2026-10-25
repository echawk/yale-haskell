#!/bin/sh
# Builds KiCS2's REPL, kics2i, with Yale Haskell (doc/plans/KICS2.md,
# step 5), after setup.sh and libs.sh, and makes a KICS2HOME for it:
#   1. KiCS2.REPL's Haskell, written by the distribution's kics2c into the
#      distribution's .curry directories (as setup.sh does KiCS2.Compile);
#   2. those modules and REPLBoot.hs in build/kics2/kics2i/src, built as
#      build/kics2/kics2i/kics2i by $YALE (a 16 GB heap: the Prelude);
#   3. build/kics2/home, the installation kics2i reads ($KICS2HOME): the
#      Yale-built kics2c and frontend, the library compiled by libs.sh,
#      a cleancurry, and a `stack` (KiCS2 runs `stack ... exec -- ghc
#      --make ...`) that builds the program with yale-haskell against
#      the kics2-libs package instead.
# Then: PATH=build/kics2/home/shim:$PATH KICS2HOME=build/kics2/home
#       build/kics2/kics2i/kics2i
set -e
top=$(cd "$(dirname "$0")/../../.." && pwd)
dist=$top/ref/kics2-dist/kics2-3.5.0-arm64-darwin
out=$top/build/kics2/kics2i
home=$top/build/kics2/home
db=${CABALDIR:-$top/build/mcabal}/yale-3.1.0.0/packages
if [ -z "$YALE" ]; then
  YALE=$top/bin/yale-haskell
  [ -x "$top/build/kics2-tree/bin/yale-haskell" ] && YALE=$top/build/kics2-tree/bin/yale-haskell
fi

case "$1" in
  --home-only) ;;
  *)
  # 1. the REPL's Haskell
  tmphome=${TMPDIR:-/tmp}/kics2-home.$$
  mkdir -p "$tmphome"
  (cd "$dist/src" && ln -sf ../bin bin && ln -sf ../lib lib &&
   HOME=$tmphome ../bin/.local/kics2c -v1 \
     -i ".:../lib:$(ls -d ../.cpm/packages/*/src | tr '\n' ':' | sed 's/:$//')" \
     KiCS2.REPL)
  rm -rf "$tmphome"

  # 2. kics2i
  rm -rf "$out/src"
  mkdir -p "$out/src"
  for d in "$dist/src/.curry/kics2-3.5.0" "$dist/lib/.curry/kics2-3.5.0" \
           "$dist"/.cpm/packages/*/src/.curry/kics2-3.5.0; do
    (cd "$d" && find . -name 'Curry_*.hs' | cpio -pdm "$out/src" 2>/dev/null)
  done
  cp "$dist/boot/REPLBoot.hs" "$out/src/"
  (cd "$out/src" &&
   "$YALE" --haskell98 --modern-prelude -D__GLASGOW_HASKELL__=908 \
     --package-db "$db" build REPLBoot.hs -o "$out/kics2i")
  ;;
esac

# 3. KICS2HOME
mkdir -p "$home/bin/.local" "$home/shim"
ln -sfn "$dist/include" "$home/include"
ln -sfn "$top/build/kics2/lib/lib" "$home/lib"
ln -sf "$top/build/kics2/kics2c/kics2c" "$home/bin/.local/kics2c"
ln -sf "$top/build/mcabal/bin/curry-frontend" "$home/bin/kics2-frontend"
cat > "$home/bin/cleancurry" <<'EOF'
#!/bin/sh
# removes the files KiCS2 generated for the given modules
for m in "$@"; do
  m=${m%.curry}
  rm -f ".curry/kics2-3.5.0/$m."* ".curry/kics2-3.5.0/Curry_$m."*
done
EOF
cat > "$home/shim/stack" <<EOF
#!/bin/sh
# KiCS2's \`stack --stack-yaml .. --stack-root .. exec -- ghc ARGS\`, as
# yale-haskell: the GHC options it cannot use are dropped, the library
# comes from the kics2-libs package (its -i path is dropped), and the
# executable is the main file without .hs, where GHC --make puts it.
while [ "\$#" -gt 0 ] && [ "\$1" != "--" ]; do shift; done
[ "\$1" = "--" ] && shift
[ "\$1" = "ghc" ] && shift
incs= main=
for a in "\$@"; do
  case "\$a" in
    -i*) for p in \$(echo "\${a#-i}" | tr ':' ' '); do
           case "\$p" in $home/lib*) ;; *) incs="\$incs -i \$p" ;; esac
         done ;;
    *.hs) main=\$a ;;
    *) ;;
  esac
done
[ -n "\$main" ] || { echo "stack shim: no main file in: \$*" >&2; exit 1; }
exec "$YALE" --haskell98 --modern-prelude -D__GLASGOW_HASKELL__=908 \\
  --package-db "$db" \$incs build "\$main" -o "\${main%.hs}"
EOF
chmod +x "$home/bin/cleancurry" "$home/shim/stack"
echo "kics2i: $out/kics2i  KICS2HOME: $home  PATH: $home/shim"
