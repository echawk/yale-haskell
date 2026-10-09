# Plan: Lisps other than SBCL

The claim in `todo` that mumble only runs on SBCL is about our *current
mumble layer*, not the dialect.  Mumble is about 2,700 lines of CL
macros and packages (src/mumble/cl-*.lisp); the compiler is ordinary
code on top.  Porting is mostly finding the SBCL-specific bits.

## What is SBCL-specific (2026-10-09)

Files mentioning `sb-`:
- mumble layer: `cl-setup.lisp`, `cl-config.lisp`, `cl-definitions.lisp`
  (packages, file and process primitives, saving images);
- runtime: `prims.mumble` (`sb-unicode` for Char,
  `sb-c::mask-signed-field` for Data.Bits), `system-prims`,
  `handle-prims`, `io-errors`, `runtime-utils`;
- compiler: `lexer.mumble`, `repl.mumble` (`run-program`, profiler);
- build: `tools/build/*.lisp` (`save-lisp-and-die`, `sb-sprof`).

Assumptions that are not `sb-` names but matter: fixnum width (Int is
63-bit on SBCL x86-64 and arm64; ECL and CCL differ), `char-code-limit`
(Unicode), and `(safety 0)` code relying on declarations being trusted.

## Steps

1. **ECL first** (started in 67165fd, "add ecl feature flags").  Get the
   mumble layer and the compiler to load, then the Prelude to compile.
   Replace each `sb-` use with a portable library or a `#+sbcl` /
   `#+ecl` pair: cl-unicode for the Unicode predicates (already
   installed), `uiop:run-program` for processes, `uiop:` for files and
   the environment, `(ldb (byte 63 0) ...)`-style masking for Data.Bits.
2. **Int width** becomes a constant from the host
   (`most-positive-fixnum`); Data.Bits already uses it.
3. **CCL** next: a second non-SBCL Lisp keeps us honest.
4. **The build**: `save-lisp-and-die` → `uiop:dump-image` /
   ASDF `program-op` (doc/ASDF-PORTING.md).
5. **CI**: run the test suite on each Lisp.

Done when `tests/run-tests` passes on ECL (allowing slower runs).
