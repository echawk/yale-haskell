#!/bin/sh
# Stand-in for a Z3 that never answers (tests/liquid/tests.lisp, YHS-0.2): reads
# its commands and is silent, as Z3 is on tests/liquid/fq/pos/hex.ts.fq.
exec cat >/dev/null
