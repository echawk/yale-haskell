#!/bin/sh
#
# survey.sh -- load each MicroCabal module in dependency order and print
# the first lines of its errors (doc/plans/MICROCABAL.md).
#
#   tools/microcabal/survey.sh [-n LINES]
#
# Needs the clone in ref/MicroCabal and the patches of this directory
# applied (tools/microcabal/apply-patches.sh), if any.

cd "$(dirname "$0")/../.." || exit 1
top=$(pwd)
lines=5
[ "$1" = "-n" ] && lines=$2
src=$top/ref/MicroCabal/src
[ -d "$src" ] || { echo "no $src; see doc/plans/MICROCABAL.md" >&2; exit 1; }
cd "$src" || exit 1
ok=0 total=0
for f in Text/ParserComb.hs MicroCabal/Regex.hs MicroCabal/Glob.hs \
         MicroCabal/Unix.hs MicroCabal/YAML.hs MicroCabal/Env.hs \
         MicroCabal/Cabal.hs MicroCabal/Macros.hs MicroCabal/Parse.hs \
         MicroCabal/Normalize.hs MicroCabal/StackageList.hs \
         MicroCabal/Backend/GHC.hs MicroCabal/Backend/MHS.hs \
         MicroCabal/Main.hs; do
  total=$((total+1))
  out=$(perl -e 'alarm 300; exec @ARGV' "$top/bin/yale-haskell" --haskell98 --modern-prelude \
        -e ":load $f" 2>&1 | grep -v '^$')
  case "$out" in
    *"Ok, modules loaded"*) ok=$((ok+1)); echo "ok    $f" ;;
    *) echo "FAIL  $f"; echo "$out" | head -"$lines" | sed 's/^/      /' ;;
  esac
done
echo "$ok of $total modules load"
