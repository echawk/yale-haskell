# Common environment for the SBCL build scripts.  Sourced, not run.
# Y2 defaults to the root of this checkout.

: "${Y2:=$(cd "$(dirname "$0")/../.." && pwd)}"
: "${SBCL:=sbcl}"
HASKELL=$Y2
PRELUDE=$Y2/progs/prelude
PRELUDEBIN=$PRELUDE/sbcl
HASKELL_LIBRARY=$Y2/progs/lib
export Y2 HASKELL PRELUDE PRELUDEBIN HASKELL_LIBRARY

# Every directory holding compiled output; the compilation unit utility
# expects an "sbcl" subdirectory next to each source file.  com/ is
# skipped since com/sbcl holds these scripts.
source_dirs () {
  find "$Y2" \( -name .git -o -path "$Y2/com" \) -prune -o \
       \( -name '*.scm' -o -name '*.lisp' -o -name '*.hu' \) -print |
    while read -r f; do dirname "$f"; done | sort -u
}

make_bin_dirs () {
  source_dirs | while read -r d; do mkdir -p "$d/sbcl"; done
}

run_sbcl () {
  "$SBCL" --dynamic-space-size 4096 --non-interactive --no-userinit "$@"
}
