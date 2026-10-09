# Plan: from mumble to Common Lisp

Goal: the compiler as ordinary Common Lisp — easier for newcomers,
portable, usable as a library — without a big-bang rewrite.

## Where we are

- 145 `.mumble` files, about 33,000 lines, read in package
  `MUMBLE-USER` with mumble's readtable.  Mumble's CL implementation is
  macros (src/mumble/cl-*.lisp), so mumble *already* compiles to CL.
- Plain-CL files already live alongside: src/cli/cli.lisp,
  src/ffi/ffi-runtime.lisp.  Mumble code calls CL as `lisp:foo` (101
  uses in the compiler); CL code calls mumble functions by their
  `MUMBLE-USER` symbols.  So files can be converted one at a time.

## What stays as a CL macro library

The compiler's architecture is built on a few mumble facilities that
should become a small CL library (`yale-haskell/support`), not be
expanded away:
- `define-struct` (131 uses) — AST and IR structures with slot types,
  defaults and bit slots;
- `define-walker` / `define-walker-method` / modify walkers (68) —
  the pass structure;
- `dynamic-let` (special variables) and `define-integrable`
  (inline functions) map directly to CL.

## The mechanical translation

- `define` → `defun` / `defparameter`; `define-syntax` → `defmacro`;
  `'#t`/`'#f` → `t`/`nil`; `null?`, `pair?`, `eq?` ... → CL names;
  `(function f)` stays; `lisp:foo` → `foo`.
- **The trap: `'#f` and `'()` are the same object** in this mumble, and
  code relies on it (an empty list as false, and the reverse).  The
  converter must not "fix" these; review by hand where a function's
  result is both a list and a flag (we hit this twice in the GRIN work,
  hence the `'no-arrows` marker).
- **Comments must survive.**  A `read`/`print` round trip loses them.
  Use a comment-preserving reader (Eclector's concrete syntax trees) or
  a token-level rewriter that edits the text in place.

## Steps

1. Write the converter (a tool, `tools/mumble2cl/`) and run it on one
   small, well-tested directory (`cfn/` or `depend/`).  The test suite
   (199 tests) must stay green.
2. The GRIN back end (newest, best understood), then the back end and
   FLIC.
3. The runtime (`src/runtime/`), which is what generated code calls —
   needs care for performance (`define-integrable`, declarations).
4. Parser, type checker, import/export, last: largest and most
   entangled with mumble's struct and walker macros.
5. Remove the mumble layer when nothing uses it.

Alongside, the clean-ups the `todo` asks for:
- not writing scratch files: the REPL writes Scratch files and the
  compiler writes `.mumble`/`.fasl`/interface files.  Give the
  compilation-unit system an in-memory mode (source from a string, code
  loaded without a file) and use it for the REPL and the Lisp interop
  API;
- configuration: compiler settings (printers, optimizers, back end,
  GRIN optimizations, search paths) as one options object that the
  CLI, the REPL and the Lisp API all set, instead of scattered globals.
