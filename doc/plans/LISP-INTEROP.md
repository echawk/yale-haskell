# Plan: Haskell and Common Lisp together

Today Haskell can call Lisp (LispName primitives in interface files)
and C (the FFI).  The other direction — Lisp calling Haskell — and
mixing the two in one source file are not there.  None of it depends on
leaving mumble: the compiler runs in the same image as the program, and
its output is Common Lisp.

Read first: the 1993 system's Lisp interface,
`doc/lisp-interface/lisp-interface.dvi`, which had some of this.

## 1. Calling Haskell from Lisp

- **A Lisp-side API** in a plain-CL package (`YALE-HASKELL`, next to
  src/cli/ and src/ffi/):
  - `(hs:load "file.hs")` / `(hs:compile-string "...")` — the REPL's
    incremental compiler (`<interactive-N>` modules,
    command-interface/incremental-compiler.mumble) without the prompt.
  - `(hs:eval "expr" [type])` — compile an expression, run it, convert
    the result.
  - `(hs:function "Module.name")` — a Lisp function that calls a
    Haskell function: arguments converted to Haskell, the result forced
    and converted back.
- **Conversions**, driven by the Haskell type as the FFI's are
  (backend/interface-codegen.mumble already has
  `haskell-list->list`, `make-haskell-string`, ...): Int/Integer ↔
  integer, Double ↔ double-float, Char ↔ character, Bool ↔ t/nil,
  String ↔ string, [a] ↔ list, tuples ↔ lists or vectors, Maybe ↔
  value/nil, IO a ↔ run it.  Other types pass through as opaque
  objects.
- **`foreign export lisp`**: a declaration form that generates a named
  Lisp function with these conversions, so compiled Lisp code can call
  Haskell without the string API.

## 2. Haskell as a reader macro

- A dispatch macro, e.g. `#H{ ... }` (expression) and `#H[ ... ]`
  (declarations), installed by an `enable-haskell-syntax` function or a
  named readtable.
- At read time it hands the text to the incremental compiler and
  returns the generated Lisp: for an expression, a form evaluating it
  (converted to Lisp by its type); for declarations, a `progn` of the
  definitions.
- Free Lisp variables inside Haskell text: a small antiquote, e.g.
  `$x` for a Lisp variable passed in as an argument of a known type.
- Errors are reported as reader errors with the Haskell compiler's
  message and position.
- Compile time: one compile per read; cache by text hash so reloading
  a file does not recompile unchanged blocks.

## Steps

1. The API's `eval` over the REPL machinery, with conversions for
   basic types; tests in a new `tests/lisp/` run by an SBCL script.
2. `hs:function`, then `foreign export lisp`.
3. The reader macro on top of step 1.
4. Documentation (doc/LISP-INTEROP.md) and an example: a Lisp program
   that uses a Haskell parser.
