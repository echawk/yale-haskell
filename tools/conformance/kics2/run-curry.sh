#!/bin/sh
# run-curry.sh DIR MODULE [GOAL]: compiles the Curry program MODULE (in
# DIR) with the Yale-built kics2c and Yale Haskell, against the packages
# kics2-runtime and kics2-libs (setup.sh, libs.sh), and runs it.  Without
# GOAL it runs MODULE's main; with GOAL (an expression, with its type when
# it is overloaded: perm [1,2,3::Int]) it evaluates GOAL.  An IO action is
# run, a value's values are printed (depth first), as kics2's :eval does.  The Main
# module is the one KiCS2.Linker's mainModule writes.
# $YALE is the yale-haskell to use.
set -e
top=$(cd "$(dirname "$0")/../../.." && pwd)
YALE=${YALE:-$top/bin/yale-haskell}
kics2c=$top/build/kics2/kics2c/kics2c
db=${CABALDIR:-$top/build/mcabal}/yale-3.1.0.0/packages
dir=$1 mod=$2 goal=$3
work=${TMPDIR:-/tmp}/run-curry.$$
mkdir -p "$work/home" "$work/bin"
trap 'rm -rf "$work"' EXIT
ln -sf "$top/build/mcabal/bin/curry-frontend" "$work/bin/kics2-frontend"
cp -R "$dir/." "$work/"
cd "$work"
target=$mod
if [ -n "$goal" ]; then
  { echo "import $mod"; echo; echo "kics2MainExp = $goal"; } > Kics2Goal.curry
  target=Kics2Goal
fi
HOME=$work/home "$kics2c" -v0 -i ".:$top/build/kics2/lib/lib" "$target" >&2
case $target in
  *.*) hsmod=$(echo "$target" | sed 's/\.\([^.]*\)$/.Curry_\1/') ;;
  *) hsmod=Curry_$target ;;
esac
hs=.curry/kics2-3.5.0/$(echo "$hsmod" | tr . /).hs
# as KiCS2.Linker's mainExpr: deterministic or not (d_C_ or nd_C_), an
# IO action or a value whose values are printed
name=main
[ -n "$goal" ] && name=kics2MainExp
if grep -q "^d_C_$name ::" "$hs"; then det=d; else det=nd; fi
sig=$(awk -v f="${det}_C_$name" '$1 == f && $2 == "::" {on=1} on && $1 == f && $2 != "::" {exit} on' "$hs")
case $det,$sig in
  d,*C_IO*) run="evalDIO d_C_$name" ;;
  nd,*C_IO*) run="evalIO nd_C_$name" ;;
  d,*) run="evalD d_C_$name" ;;
  *) run="printDFS print nd_C_$name" ;;
esac
cat > Main.hs <<EOF
module Main where
import Basics
import $hsmod

main :: IO ()
main = $run
EOF
"$YALE" --haskell98 --modern-prelude -D__GLASGOW_HASKELL__=908 \
  --package-db "$db" -i .curry/kics2-3.5.0 Main.hs 2>&1 |
  grep -v 'INFINITE-LOOP-FUNCTION\|has an infinite loop'
