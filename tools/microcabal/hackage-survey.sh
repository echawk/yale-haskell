#!/bin/sh
#
# hackage-survey.sh -- install Hackage packages with MicroCabal's Yale
# backend (tools/microcabal/mcabal) and report which build.
#
#   tools/microcabal/hackage-survey.sh [-t SECONDS] [PKG ...]
#
# Without PKGs, the list below (popular libraries, few of them needing
# Template Haskell).  Each is installed with -r (its dependencies too)
# into $CABALDIR, default build/mcabal; logs go to $CABALDIR/survey/PKG.log.
# A package already installed counts as built.  Prints "ok" or "FAIL"
# and the first error line of each, then the totals.

cd "$(dirname "$0")/../.." || exit 1
top=$(pwd)
limit=900
[ "$1" = "-t" ] && { limit=$2; shift 2; }
CABALDIR=${CABALDIR:-$top/build/mcabal}
export CABALDIR
mkdir -p "$CABALDIR/survey" "$CABALDIR/work"
[ -f "$CABALDIR/packages.txt" ] || tools/microcabal/mcabal update || exit 1
[ $# -eq 0 ] && set -- \
  split safe extra data-default dlist tagged base-orphans colour \
  microlens indexed-traversable splitmix assoc these strict \
  semigroupoids primitive vector async parser-combinators megaparsec \
  case-insensitive utility-ht either transformers-base mmorph \
  call-stack StateVar HUnit base-compat integer-logarithms data-fix \
  comonad bifunctors contravariant distributive profunctors free \
  attoparsec prettyprinter ansi-wl-pprint optparse-applicative \
  aeson lens
ok=0 total=0
for p in "$@"; do
  total=$((total+1))
  log=$CABALDIR/survey/$p.log
  (cd "$CABALDIR/work" &&
   perl -e 'alarm shift; exec @ARGV' "$limit" \
     "$top/tools/microcabal/mcabal" -r install "$p") > "$log" 2>&1
  if [ $? -eq 0 ]; then
    ok=$((ok+1)); echo "ok    $p"
  else
    echo "FAIL  $p"
    grep -v '^mcabal: \|^$' "$log" | head -3 | cut -c1-200 | sed 's/^/      /'
  fi
done
echo "$ok of $total packages built"
