# Common environment for the SBCL build scripts.  Sourced, not run.
# Y2 defaults to the root of this checkout.

: "${Y2:=$(cd "$(dirname "$0")/../.." && pwd)}"
: "${SBCL:=sbcl}"
HASKELL=$Y2
PRELUDE=$Y2/progs/prelude
HASKELL_LIBRARY=$Y2/progs/lib
BUILD=$Y2/build/sbcl
PRELUDEBIN=$BUILD/prelude
LIBRARYBIN=$BUILD/lib
export Y2 HASKELL PRELUDE PRELUDEBIN HASKELL_LIBRARY LIBRARYBIN

run_sbcl () {
  "$SBCL" --dynamic-space-size 4096 --non-interactive --no-userinit "$@"
}
