# Tests for yale-liquid

Run them with `make liquid-test` (or `tests/liquid/run-tests`); they need
SBCL and, for the solver tests, Z3 (`/opt/homebrew/bin/z3`, `z3` on `PATH`,
or `$YALE_LIQUID_Z3`).  Without Z3 the solver tests are skipped and say so.

| Directory | What | Expected |
|---|---|---|
| `tests.lisp` | unit tests: parsing, printing round trips, substitution, sort checking, SMT encoding, Z3 queries, the spec parser on hand-written examples | all pass |
| `fq/pos/` | liquid-fixpoint's `tests/pos/*.fq` | SAFE |
| `fq/neg/` | liquid-fixpoint's `tests/neg/*.fq` | UNSAFE |
| `fq/expected-failures.txt` | the vendored `.fq` files this solver does not get right yet, with the reason | (listed, not failures) |
| `lh/assumptions/` | LiquidHaskell's library specifications (`*_LHAssumptions.hs`, the `liquid-prelude` modules) | every `{-@ @-}` parses |
| `lh/annotations/` | the `{-@ ... @-}` comments of LiquidHaskell's test programs, extracted | parse coverage is reported and must not drop below the recorded floor |

## Provenance of the vendored data

All vendored files are unchanged copies (or, for `lh/annotations/`, verbatim
extracts) of BSD-3-licensed upstream files.  Their licences are in
`licenses/`.

- **liquid-fixpoint**, https://github.com/ucsd-progsys/liquid-fixpoint at
  commit `0b924442ce26a8f270bffac18ba6295bc7411646` (2026-10-16):
  - `fq/pos/*.fq` from `tests/pos/`, `fq/neg/*.fq` from `tests/neg/`;
  - licence: `licenses/LICENSE.liquid-fixpoint` (upstream `LICENSE`).
- **LiquidHaskell**, https://github.com/ucsd-progsys/liquidhaskell at commit
  `aae574e92629d33c88269fa733fc12fa85500086` (2026-10-17):
  - `lh/assumptions/` from `src/` (the `*_LHAssumptions.hs` modules and
    their specification-only siblings), `liquid-prelude/src/`,
    `liquid-vector/src/` and `liquid-parallel/src/`, keeping upstream's
    relative paths;
  - `lh/annotations/*.txt` from the test programs under `tests/` (one file
    per upstream test directory; each comment is preceded by a line
    `-- FILE path:line:column` giving its upstream location);
  - licence: `licenses/LICENSE.liquidhaskell` (upstream `LICENSE`).

The code in `src/liquid/` ports algorithms and grammars from the same two
commits; each file names the upstream modules it follows.
