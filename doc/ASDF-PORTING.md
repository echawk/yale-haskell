# ASDF Porting Notes for Yale Haskell

Status (2026-10-07): working.  `(asdf:load-system :yale-haskell)` loads
mumble (`mumble.asd`), the compiler and the Haskell 98 prelude into a live
image; `(asdf:test-system :yale-haskell)` runs `make test`.  Mumble no
longer touches the standard readtable or unlocks `COMMON-LISP`, so other
systems (e.g. cl-ppcre) load into the same image before or after it.

## 1. The existing build mechanism

Yale Haskell does **not** use ASDF, MK:DEFSYSTEM, or any standard CL
system definition.  It has a bespoke build with three layers:

### Layer 1: CL bootstrap (`src/mumble/*.lisp`)

Seven plain Common Lisp files implement "mumble", the Scheme-like
dialect the compiler is written in:

| File | Lines | Role |
|---|---|---|
| `cl-setup.lisp` | 46 | Creates `MUMBLE` and `MUMBLE-IMPLEMENTATION` packages; adds `LISP` as a nickname for `COMMON-LISP` |
| `cl-config.lisp` | 40 | The host's file types and name (`*lisp-binary-file-type*`, `*lisp-implementation-name*`), split out of `cl-init.lisp` |
| `cl-support.lisp` | 108 | Compile-time macros: `define-mumble-function`, `define-mumble-macro`, `define-mumble-import`, `define-mumble-synonym`, `define-mumble-constant`, `define-setf-method` shim |
| `cl-definitions.lisp` | 1368 | The big one: maps every mumble construct to CL (`define`→`defun/defparameter`, `begin`→`progn`, `cond` with `else`, `letrec`, `dynamic-let`, etc.); defines the custom `mumble::load`, `mumble::compile-file`; defines `*mumble-readtable*` (a private copy with `#t`/`#f`); defines `source-file-type` = `.mumble` |
| `cl-types.lisp` | 100 | Mumble type declarations |
| `cl-structs.lisp` | 729 | Extended struct system (`define-struct` with `include`, `predicate`, `slots`, annotations) |
| `mumble-user.lisp` | 6 | Creates `MUMBLE-USER`, the package mumble programs are read in |
| `wcl-patches.lisp` | 68 | WCL-only patches (unused on SBCL) |

The Makefile build loads these via `src/mumble/cl-init.lisp`
(`load-compiled-cl-file`, compiling each to `build/<lisp>/src/mumble/`
when stale); the ASDF build has them as `:file` components of `mumble`.

### Layer 2: The mumble compilation-unit system (`src/mumble/compile.mumble`)

`compile.mumble` implements a makefile-like dependency system **on top
of** the mumble language.  It defines `define-compilation-unit`, a
macro that builds a tree of compilation units with `source-filename`,
`binary-filename`, `require` (dependencies), and nested `unit` clauses.

Key characteristics that prevent direct ASDF translation:

1. **Custom file type.**  `source-file-type` is `.mumble`, not `.lisp`.
   The `.mumble` files use `#t`/`#f` reader macros and mumble syntax
   (`define`, `begin`, `else` in `cond`), so they cannot be read by a
   standard CL reader.

2. **Custom `compile-file`.**  `mumble::compile-file` (in
   `cl-definitions.lisp`, line 1062) wraps `cl:compile-file` but adds
   `$Y2`/environment-variable expansion via `expand-filename` and
   `.mumble` extension defaulting.  ASDF's `compile-op` calls
   `cl:compile-file` directly, bypassing this.

3. **Custom `load`.**  `mumble::load` (line 988) intercepts loads to
   check binary-vs-source freshness and expand `$Y2` paths.  ASDF's
   `load-op` calls `cl:load` directly.

4. **Out-of-tree build output.**  `compile.binary-place` maps
   `$Y2/<dir>/` to `$Y2/build/<lisp>/<dir>/`.  ASDF's output file
   resolution is different.

5. **Inter-file variable dependencies.**  `cl-definitions.lisp` uses
   `*lisp-binary-file-type*` etc. at compile time.  These used to be
   defined inside `cl-init.lisp`; they are now in `cl-config.lisp`, an
   ordinary component loaded before it.

### Layer 3: Unit definition files (`src/compiler/system.mumble` etc.)

`system.mumble` loads 18 unit-definition `.mumble` files, each
containing `define-compilation-unit` forms that specify the dependency
tree of the ~120 compiler source files.  The full load order is:

```
support.mumble          → compile, utils, pprint, format
ast/ast.mumble          → ast-td, modules, type-structs, tc-structs, valdef-structs, definitions, exp-structs, predicates
top/top.mumble          → global (has-utils, core-definitions, core-symbols, core-init, globals, has-macros), top-level (phases, system-init, errors, tuple, symbol-table)
util/haskell-utils.mumble → constructors, prec-utils, walk-ast, pattern-vars, instance-manager, signature, type-utils, annotation-utils
printers/printers.mumble → printer-support, printers (print-exps, print-modules, print-types, print-ntypes, print-valdefs)
parser/parser.mumble    → parser-globals, parser-macros, lexer, token, parser-driver, module-parser, interface-parser, decl-parser, type-parser, typedecl-parser, exp-parser, annotation-parser, pattern-parser, parser-debugger
import-export/ie.mumble → ie-utils, import-export, init-modules, top-definitions, locate-entity, ie-errors
tdecl/tdecl.mumble      → type-declaration-analysis, tdecl-utils, alg-syn, class, instance
derived/derived.mumble  → derived-instances, ast-builders, eq-ord, ix-enum, text-binary
prec/prec.mumble        → scope, prec-parse
depend/depend.mumble    → dependency-analysis
type/type.mumble        → type-macros, unify, type-main, type-decl, dictionary, default, pattern-binding, type-vars, expression-typechecking, type-error-handlers
cfn/cfn.mumble          → main, misc, pattern
flic/flic.mumble        → flic-td, flic-structs, print-flic, ast-to-flic, flic-walker, copy-flic, invariant
backend/backend.mumble  → optimize, strictness, box, codegen, interface-codegen
runtime/runtime.mumble  → runtime-utils, prims, io-primitives, array-prims, debug-utils, tuple-prims, io-errors, system-prims, handle-prims
csys/csys.mumble        → cache-structs, compiler-driver, dump-params, dump-macros, dump-interface, dump-flic, dump-cse
command-interface/command-interface.mumble → command, command-utils, incremental-compiler
```

### The build flow

```
tools/build/compiler.lisp
  (load "src/mumble/cl-setup")
  (load "src/mumble/cl-init")
    → load "src/mumble/cl-config"         ; *lisp-implementation-name* etc.
    → load-compiled-cl-file "cl-setup"    ; compiles if needed
    → load-compiled-cl-file "cl-support"
    → load-compiled-cl-file "cl-definitions"
    → load-compiled-cl-file "cl-types"
    → load-compiled-cl-file "cl-structs"
    → load-compiled-cl-file "mumble-user"
    → (load "$Y2/src/compiler/system")    ; loads unit definitions
    → (compile-haskell)                   ; compile-and-load-unit-list
```

`tools/build/prelude.lisp` extends this by compiling the Haskell
prelude.  `tools/build/image.lisp` saves a standalone executable.

## 2. The ASDF systems

### `mumble.asd` — the `mumble` system

Mumble is a language of its own, so it has its own system, independent of
Haskell (`$Y2` is not needed to load it):

```lisp
(defsystem :mumble
  :pathname "src/mumble/" :serial t
  :components ((:file "cl-setup") (:file "cl-config") (:file "cl-support")
               (:file "cl-definitions") (:file "cl-types") (:file "cl-structs")
               (:file "mumble-user")
               (:mumble-file "units") (:mumble-file "compile")
               (:mumble-file "utils") (:mumble-file "pprint") (:mumble-file "format")))
```

`mumble-file` is a `cl-source-file` subclass (type `"mumble"`) whose
`compile-op`/`load-op` run inside `mumble-asd:call-with-mumble-syntax`,
which binds `*package*` to `MUMBLE-USER` and `*readtable*` to
`*mumble-readtable*`.  So the library `.mumble` files are ordinary ASDF
components, compiled into ASDF's output cache.  `units.mumble` defines
`compilation-units`, which `support.mumble` defines in the Makefile build.
Loading the system pushes `:mumble` onto `*features*`.

Use `(mumble-asd:with-mumble-syntax () ...)` to call or load mumble code
from CL.

### `yale-haskell.asd` — `yale-haskell`, `yale-haskell/haskell-1.2`, `yale-haskell/test`

The compiler's ~120 `.mumble` files stay under mumble's own
compilation-unit system (`define-compilation-unit` in
`src/compiler/*/…mumble`): it already does dependency-ordered,
timestamp-driven compilation into `build/<lisp>/`, shared with the
Makefile.  `yale-haskell` depends on `mumble` and, after loading,

1. sets the environment the compiler reads — `Y2`, `PRELUDE`,
   `PRELUDEBIN`, `HASKELL_LIBRARY`, `LIBRARYBIN` — as the Makefile's
   `dialect_env` and `bin/yale-haskell` do;
2. `(mumble:load "$Y2/src/compiler/system")` and `(compile-haskell)`
   (`system.mumble` skips `support.mumble` when `:mumble` is a feature);
3. compiles the prelude with `tools/build/prelude.lisp`'s settings if
   `build/<lisp>/<dialect>/prelude/` is empty, then `compile/load`s it.

The dialect is fixed per image: `yale-haskell` uses
`$YALE_HASKELL_DIALECT` or `haskell98`; `yale-haskell/haskell-1.2` uses
1.2.  Loading a second dialect is an error.

`tools/asdf/api.lisp` defines the `yale-haskell` package —
`compile-file`, `load-file`, `run-file`, `repl`, `dialect` — which binds
`*package*` and `*readtable*` as the compiler requires (it interns
symbols in the current package).

```lisp
(asdf:load-system :yale-haskell)
(yale-haskell:run-file "examples/demo/queens.hs")
(asdf:test-system :yale-haskell)          ; make test
```

Like the Makefile, the prelude unit is `:stable`: after editing
`lib/<dialect>/prelude/`, delete `build/<lisp>/<dialect>/prelude/`.

## 3. Fixes that made this possible

| Problem | Fix |
|---|---|
| `#t`/`#f` installed on the standard readtable | `*mumble-readtable*` is `(copy-readtable nil)` with the macros; `mumble::load`, `mumble::compile-file`, `lisp-read` and `read-lisp-object` bind it; `tools/build/*.lisp` switch to it after `(in-package :mumble-user)`; the saved image's toplevel sets it |
| `COMMON-LISP` unlocked | No longer unlocked.  `dynamic-let`/`dynamic` omitted `CL` variables from `special` declarations (they are special already); `pprint.mumble` assigns CL's `*print-…*` variables instead of `define`-ing them |
| `cl-types.lisp`, `cl-structs.lisp` had no `in-package` | Added; they only worked because `cl-init.lisp` compiled them with `*package*` already `MUMBLE-IMPLEMENTATION` (otherwise `define-mumble-type` was compiled as a function call) |
| Implementation variables defined inside `cl-init.lisp` | Moved to `cl-config.lisp` |
| `sb-posix:putenv` in the .asd | `uiop:getenv` setf |

## 4. Feature conditionals and non-portable bits

The CL layer still has `#+` branches for eight historic Lisps (SBCL, CMU
CL, Lucid, Allegro, LispWorks, AKCL/GCL, MCL, WCL); only SBCL is tested.
Remaining host-specific points:

- `cl-setup.lisp` adds the CLtL1 `LISP` nickname to `COMMON-LISP` (the
  sources use `lisp:` prefixes).  This is a global change to the image;
  harmless unless another system defines a `LISP` package.
- `define-setf-method`/`get-setf-method` are shimmed over the ANSI names
  (`cl-support.lisp`).
- `cl-definitions.lisp` uses the deprecated `(eval-when (eval compile
  load))` situation names (style warnings).
- `tools/build/image.lisp` and the runtime use `sb-ext`/`sb-posix`
  directly.

Testing on ECL and ABCL is a later goal (see `notes`).

## 5. Next steps

- **External dependencies.**  `:depends-on (:cl-unicode)` can now be
  added when LG-UNICODE needs it.
- **Mumble as its own project.**  `mumble.asd` does not depend on Yale
  Haskell; the only remaining coupling is `compile.mumble`'s
  `$Y2/build/<lisp>/` output tree for units under `$Y2`.  Moving mumble
  to its own repository would make that root configurable.
- **Second host.**  Try `(asdf:load-system :mumble)` on ECL/CCL; failures
  there are in the CL layer's `#+` branches.

## 6. Verification

```
$ sbcl --non-interactive --load ~/quicklisp/setup.lisp \
    --eval '(push (truename ".") asdf:*central-registry*)' \
    --eval '(asdf:load-system :yale-haskell/haskell-1.2)' \
    --eval '(yale-haskell:run-file "tests/haskell-1.2/smoke/hello.hs")' \
    --eval '(ql:quickload :cl-ppcre)' \
    --eval '(print (cl-ppcre:scan-to-strings "a(b+)" "xabbby"))'
Hello from Yale Haskell!
...
"abbb"
```

With `:yale-haskell` (Haskell 98): `(read-from-string "#t")` is a reader
error in the standard readtable and `(sb-ext:package-locked-p :cl)` is
true after loading.
