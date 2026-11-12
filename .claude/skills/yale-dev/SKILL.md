---
name: yale-dev
description: How to build, test, debug and change the Yale Haskell compiler. Covers make targets, tests/run-tests and the .hs/.stdout/.exit/.flags/.xfail/.hu conventions, dialect gating with feature?, mumble pitfalls, host portability (#+sbcl, ECL, ABCL), the unit cache, tools/bound, and --emit/REPL debugging. Use whenever changing code under src/, lib/, tools/build/ or tests/.
---

# yale-dev

## Principles (non-negotiable)
1. **Expected output comes from GHC 9.14.1 or the Haskell Report**, never from
   what Yale Haskell prints. Run `ghc -O0 T.hs && ./T > T.stdout`, or derive the
   output from the Report.
2. **`make test` and the Haskell 1.2 tests stay green** after every change.
3. **Dialect differences go through `(feature? 'name)`.** Add the feature to
   `*dialect-features*` in `src/compiler/top/globals.mumble`. Never write raw
   `(haskell98?)`.
4. **Host-specific calls stay behind `#+sbcl` in `src/mumble/` or
   `src/runtime/`**, with a portable fallback for ECL and ABCL.
5. **Mumble is not Scheme.** Read `src/mumble/README.md` and
   `src/mumble/mumble-reference.txt` before using an unfamiliar form. Copy idioms
   from the surrounding file.

## Build
```sh
make deps            # once per clone: ocicl install into ocicl/
make                 # compiler + Haskell 98 prelude + image; logs in build/sbcl/logs/
make haskell-1.2     # the 1.2 dialect's image (needed for its tests)
make clean           # remove build/
```
- The compiler build reports Haskell errors without failing. The Makefile greps
  the prelude log for `Phase error`, `Recoverable error`, `Fatal error` and
  `Internal-error`.
- SBCL warnings in `build/sbcl/logs/*.log` are counted by the ratchet (after
  YHS-0.4). Do not add new ones.
- A change to the prelude (`lib/<dialect>/prelude/`) rebuilds the prelude unit.
  The unit is `:stable`, so the Makefile deletes its binaries first.

## Tests (`tests/README.md`)
```sh
make test                                   # whole haskell98 suite (~5 min)
tests/run-tests -v -j 8 tests/haskell98/language/foo.hs   # one test, verbose
tests/run-tests tests/haskell-1.2           # after make haskell-1.2
make embed-test                             # Haskell inside Lisp files
tools/bound 900 make liquid-test            # needs z3
```
- **Layout.** `tests/<dialect>/<area>/<name>.hs` (`module Main`) with:
  - `.stdout` (byte for byte);
  - `.exit` (expected status; `1` for programs the compiler must reject);
  - `.stdin`;
  - `.flags` (compiler options on line 1, e.g. `--ghc2021`);
  - `.args`;
  - `.xfail` (first line: what is missing, naming a ticket ID);
  - `.repl` (an interactive session).
- **XPASS.** An `.xfail` that passes is an XPASS and fails the run. Delete the
  `.xfail` when the feature lands.
- **Multi-module tests.** They use a `.hu` unit file next to the `.hs`, listing
  sources or other units, e.g. `$HASKELL_LIBRARY/List.hu`.
- **Parallel runs.** `-j` runs share the compiled libraries under `build/`. If
  two tests compile the same library at once, use `-j 1`.

## Running and debugging
```sh
bin/yale-haskell prog.hs a b                 # compile and run
bin/yale-haskell compile F.hs --emit scope,depend,cfn,flic,optimize,strictness,grin,codegen,lisp,asm
bin/yale-haskell -O F.hs                     # FLIC optimizer off
bin/yale-haskell --backend flic F.hs         # old back end
bin/yale-haskell -g none F.hs                # GRIN optimizations off
bin/yale-haskell repl F.hs                   # :grin :lisp :flic :asm :type :browse
YALE_HASKELL_TIME=1 bin/yale-haskell F.hs    # phase times, GC, bytes allocated
YALE_HASKELL_TRACE=... YALE_HASKELL_DEBUG=1  # traces (claude-prompt.md §2)
```
- **Unit cache.** It lives in `~/.cache/yale-haskell/`. Use
  `YALE_HASKELL_CACHE_DIR=$(mktemp -d)` for a cold, isolated cache, or
  `YALE_HASKELL_CACHE=0` to turn it off.
- **Timeouts.** Bound any command that might loop with `tools/bound SECONDS cmd`.
  `perl alarm` does not stop yale-haskell.
- **Finding code.** `doc/STRATEGY.md` maps each feature to files.
  `doc/STRATEGY-CODE.md` gives code-level detail.

## Other hosts
```sh
make LISP=ecl && YALE_HASKELL_LISP=ecl tests/run-tests -j 8
make LISP=abcl && YALE_HASKELL_LISP=abcl tests/run-tests -j 8
```
These are slow; run them under `tools/bound`. Compare with the counts in
`doc/harness/baselines.md` (from YHS-0.7). `doc/plans/PORTABILITY.md` lists
the SBCL-only tests.

## Testing (required per ticket)
- A test for every new behaviour, with GHC-derived expected output.
- A negative test (`.exit` = `1`) for every new rejection or error path.
- For a new flag, an environment variable or a phase: one test with it on and
  one with it off.
- Interface-format changes need a test that compiles a module, then imports it
  from the cache in a second run.

## Pitfalls
- **Version.** It is part of every compiled interface. Do not bump it unless the
  ticket says so (`CHANGELOG.md` explains the scheme).
- **Interface files.** Changing the type, kind or name representation means
  editing `backend/interface-codegen.mumble`, `backend/dump-interface.mumble`
  and `import-export/interface-parser.mumble` together.
- **Safety 0.** Generated code runs at `safety 0`
  (`src/mumble/cl-definitions.lisp`). A wrong declaration is silent wrong code,
  not an error. Use safe mode (`correctness` skill) to check.
- **`Int` width.** `Int` is the 63-bit fixnum. Never hard-code the width in new
  code (north-star hook).
- **Case-insensitive filesystem.** Unit names that differ only in case collide
  on macOS (`doc/STRATEGY.md` BUG-8).
