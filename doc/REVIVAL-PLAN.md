# Yale Haskell revival plan

Status: exploratory (October 2026).  This document records where the
system stands, how far it is from Haskell 98, and the work needed to
get there.

> **Paths.**  Sections 1–4 were written before the repository was
> restructured (§5).  Compiler paths such as `parser/lexer.scm:313`
> now live at `src/compiler/parser/lexer.mumble`; `cl-support/` and
> `support/` are `src/mumble/`; `runtime/` is `src/runtime/`; and
> `progs/prelude` is `lib/haskell-1.2/prelude`.  Line numbers are
> unchanged.

## 1. Where we are

The source is Yale Haskell **Y2.0.5** (1994).  It implements **Haskell
1.2**, written in "mumble", a Scheme-like dialect hosted on Common Lisp
(now `src/mumble/`).  It last built on CMU CL 16f, Lucid, Allegro,
LispWorks and AKCL, all on SPARC.

**It runs again.**  On the `ng` branch the compiler, the Prelude and a
saved image build under **SBCL 2.6.9 on arm64 macOS**:

```
make                      # compiler (~117 files), the Prelude, build/sbcl/yale-haskell
make test                 # output-comparison smoke tests
bin/yale-haskell foo.hs   # compile + run Main.main
bin/yale-haskell          # the old ":load / :run / =expr" REPL
```

The demos `queens`, `fact`, `primes` and `pascal`, plus a test that
uses deriving, `Integer` bignums and floats, all give correct output.

### What the port needed

All of the porting changes are in `cl-support/`; no compiler source was
touched.

| Problem | Fix |
|---|---|
| No `#+sbcl` branches | Add `sbcl` to every `#+(or cmu …)`.  Add SBCL `getenv`, `exit`, fasl type and implementation name. |
| No CLtL1 `LISP` package | `cl-setup.lisp` adds `LISP` as a nickname of `COMMON-LISP`. |
| No `define-setf-method` / `get-setf-method` | Shims over `define-setf-expander` / `get-setf-expansion`. |
| `defconstant` of strings re-evaluated on load | `define-mumble-constant` reuses the existing value. |
| The AST defines structs named `TYPE`, `LET`, `IF`, `RETURN-FROM` (CL symbols); a struct named `CL:TYPE` breaks SBCL's own compiler | `cl-structs.lisp` gives those structs a private Lisp name (`%STRUCT-TYPE`, …).  `is-type?` and `typecase` map to it. |
| SBCL leaves `&aux` BOA slots unbound; CMU set them to NIL, and the code relied on it (`tdecl/class.scm` `super*`) | Initialise them to NIL explicitly. |
| `:if-exists :new-version` | `:supersede` |
| Package locks (the code redeclares CL specials) | `CL` is unlocked during the build. *Temporary.* |
| `string->symbol` interns into `*package*` | The saved image sets `*package*` to `MUMBLE-USER` at startup. |

### Known rough edges

- The generated code still uses the deprecated `eval-when (eval compile)`
  names (`cl-support/cl-definitions.lisp:238,276`).  This produces a
  stream of style warnings.
- When a program fails to compile, batch mode ends with a Lisp
  backtrace instead of a clean error and exit code.
- Phase timings are printed in the wrong units (`get-run-time`
  assumes old `internal-time-units-per-second`).
- `Float` prints as `3.50000000`.  Yale's `showFloat` uses a fixed-digit
  algorithm, where H98 uses shortest representation.
- Only SBCL has been tried.  CCL and ECL should be close, since the
  same conditionals apply.

## 2. Strategy: how to bring it back to life

**Keep the architecture; replace the hosts.**  The compiler is a
complete, working, readable pipeline:

> parse → import/export → tdecl → derived → prec/scope → depend → type
> → cfn → flic → optimize → strictness → codegen → Lisp

Rewriting it in Haskell would throw away what makes it interesting:
it is a Lisp-hosted Haskell with a Lisp FFI.  The plan instead:

1. **Main host: SBCL** (fast native code, actively maintained, has
   `sb-posix` for the H98 system libraries).  **Long-term goal:
   portability across implementations**, tested on at least ECL and
   ABCL as well.  The code base is old enough (pre-ANSI, written for
   five Lisps at once) that this should be easier than for most
   projects.  To keep that open, all host-specific code stays in
   `src/mumble/`, behind `#+` conditionals, and new runtime
   primitives prefer portable CL with a thin per-host layer (e.g.
   POSIX calls).  The `Makefile` takes a `LISP=` variable for this.
   The Lucid, Allegro, LispWorks, AKCL, WCL, MCL and T branches can
   go once a second modern host builds.
2. **Modernise the build and repo** (§5) before deep language work, so
   that iteration is cheap: one command to build, one to test, CI.
3. **Get a regression suite in place**: the demos, the tutorial, the
   hbc libs, and later H98 conformance programs.  Every language change
   needs it.
4. **Move to Haskell 98 incrementally**, in the order of §4.  The
   critical path is *constructor classes → monadic IO / `do` →
   the Prelude rebuild*.  Everything else can be done in parallel.

## 3. What is missing for Haskell 98

The full findings came from comparing the compiler and Prelude with
the H98 Report (`haskell/haskell-report`, branch `h98`) and with Hugs
(`hugs98-plus-Sep2006`).  This is the condensed version.  Effort:
S = days, M = 1–2 weeks, L = several weeks, XL = redesign.

### 3.1 Already in place

These match H98 or are close enough:
- list comprehensions (no `let` qualifiers yet)
- arithmetic sequences, sections, `(- x)` as negation, unary minus
- `case`, `let`, `where` and guards
- as, irrefutable, n+k and negative-literal patterns
- overloaded literals
- datatype contexts and type synonyms
- single-parameter classes with defaults
- the monomorphism restriction (rule 1)
- default declarations
- literate scripts
- layout, including explicit braces nested inside an implicit block
  (tested)
- derived Eq, Ord and Ix
- distinct `Int` and `Integer`

Strict constructor fields already work, but through `{-#STRICT#-}`
annotations rather than `!`.  `seq` already exists internally as
`strict1`.

### 3.2 Language gaps

| Feature | Status | Effort | Notes / evidence |
|---|---|---|---|
| **Constructor classes, higher kinds, kind inference** | Missing | **XL** | A type is `tyvar \| tycon(args)`, so a variable cannot be applied (`ast/type-structs.scm:25-40`).  Contexts are `(class, tyvar)` pairs, and `unify` assumes a tycon head (`type/unify.scm:50-61`).  Also touches instance lookup (`type/dictionary.scm`), the interface dump format and `backend/interface-codegen.scm`. |
| `do` notation | Missing | M | Needs Monad first.  `do` is not a reserved word or a layout keyword (`parser/lexer.scm:313-326`, `parser/token.scm:15`). |
| Abstract `IO`, `Main.main :: IO t` | Different | M | Today `type IO a = SystemState -> IOResult a` is a synonym (`progs/prelude/PreludeIO.hs:22`), and programs are `Dialogue`s. |
| `newtype` | Missing | M | Lexer, parser, AST, tdecl, erased in cfn/backend, deriving. |
| Records (construction, update, selection, patterns) | Missing | L | Parser, AST, tdecl selector generation, typing of update, cfn, derived Show/Read, export of field names. |
| Qualified names, `import qualified … as` | Missing | L | `.` always lexes as an operator.  The symbol table is a flat name→def map (`top/symbol-table.scm`). |
| H98 import/export semantics | Different | M | `renaming`, `M..` exports, unhideable PreludeCore, no redefinition of Prelude names, C-T instance rule (`tdecl/instance.scm:37-39`), synonyms must be exported as `T(..)`, partial `T(C1)` rejected. |
| Text/Binary → Show/Read; drop `Bin` | Different | M | Prelude, `derived/text-binary.scm`, the defaulting class list (`tdecl/class.scm:81-96`), the hard-wired core symbols (`top/prelude-core-syms.scm`). |
| Deriving Bounded, H98 Enum, Show/Read for records | Missing/partial | M | `derived/` |
| Polymorphic recursion via signatures | Missing | M | Needs signature-aware dependency analysis (`depend/`, `type/type-decl.scm`). |
| Monomorphism restriction rule 2 | Different | S–M | Exporting a restricted binding is an error (`type/pattern-binding.scm:26-35`). |
| Default `(Integer, Double)` | Different | S | Currently `(Int, Double)` (`top/system-init.scm:15-19`). |
| Fixity declarations in `let`, `where` and class bodies | Missing | S–M | Only allowed at top level after the imports. |
| Hex/octal literals | Missing | S | `0x1F` lexes as `0` followed by `x1F` (tested). |
| `(,)`, `(,,)`, `(->)`, `[]` as constructors | Missing | S | Parser. |
| Parenthesised function LHS `(f . g) x = …` | Missing | S | Parse error (tested). |
| `let` in list comprehensions | Missing | S | |
| `!` strictness flags | Different | S | Map onto the existing STRICT machinery. |
| H98 pragmas; ignore unknown ones | Different | S | `{-#` always goes to Yale's annotation grammar, so unknown pragmas are syntax errors. |
| `-->` lexes as an operator, not a comment | Different | S | |
| Headerless module means `Main(main)` | Different | S | |
| `do` and `newtype` reserved; free `interface`, `renaming`, `to`, `hiding` | Different | S | |
| Unicode `Char` | Missing | M | `*max-char*` is 255.  Latin-1 is acceptable in practice (Hugs used it until 2005). |

### 3.3 Prelude and library gaps

**Prelude** (`progs/prelude/`):

- **Classes.**
  - Add `Ordering` and `compare`.
  - Enum: drop its `Ord` superclass and add `succ`, `pred`, `toEnum`
    and `fromEnum`.
  - Add `Bounded`.
  - Fix the superclasses: `Num ⇐ Eq, Show`; `Real ⇐ Num, Ord`;
    `Integral ⇐ Real, Enum`; `Ix ⇐ Ord`.
  - RealFloat: add `isNaN` and the other predicates, and make `atan2`
    a method.
  - Add `Functor` and `Monad`; these are blocked on constructor classes.
- **Types.**
  - Add `Maybe`, `Either`, `Ordering` and `FilePath`.  `Maybe` and
    `Either` currently exist only in `progs/lib/hbc`, and
    `progs/lib/cl/maybe.hs` defines a conflicting `Maybe`.
  - Make `IOError` abstract.
  - Remove `Dialogue`, `Bin` and `Assoc`.
- **Functions.**
  - Add the missing ones: `concatMap`, `replicate`, `lookup`, `curry`,
    `uncurry`, `undefined`, `seq`, `$!`, `realToFrac`, `maybe`,
    `either`, `mapM`, `mapM_`, `sequence`, `sequence_`, `=<<`,
    `putChar`, `putStr`, `putStrLn`, `getChar`, `getLine`,
    `getContents`, `ioError`, `userError`, `catch`, `readIO` and
    `readLn`.
  - Fix the 1.2 signatures: `take`, `drop`, `splitAt` and `!!` must
    take `Int`.  The I/O functions must become monadic.
  - Move `Ratio`, `Complex`, `Array`, the `zip4`-style functions,
    `nub` and similar out of the Prelude into the libraries.

**Libraries:**

| Module | Status | Work | New Lisp primitives? |
|---|---|---|---|
| Ratio, Complex | Present as `PreludeRatio` / `PreludeComplex` | Rename, Show/Read | no |
| Ix, Array | Partial | `rangeSize`.  Arrays take `(i,e)` tuples instead of `:=`, which is a breaking change; keep a compatibility module | no |
| Numeric | Partial | `showHex`, `showOct`, `showEFloat`, `showFFloat`, `showGFloat`, `floatToDigits`.  Port the report code | float predicates |
| Char | Partial | `digitToInt`, `intToDigit`, `isAlphaNum`, `lexLitChar`.  **Bug:** `isHexDigit` rejects `a-f` | no |
| List, Maybe | Mostly missing | Port the report code (pure) | no |
| Monad | Missing | Port the report code, after constructor classes | no |
| IO | Missing | Handles, `hGetLine` and the rest, IOError predicates, `bracket` | **yes**, the most |
| System | Stubs | `getArgs` returns `[""]`.  Need `exitWith` and `system` | yes |
| Directory | Missing | All 13 operations, via `sb-posix` | yes |
| Time, Locale, CPUTime | Missing (hbc `Time` is incompatible) | Pure parts from the report or Hugs | yes (clock/calendar) |
| Random | hbc version, same algorithm | Port Hugs' `System/Random.hs` | a global ref cell |

**New runtime primitives** (`runtime/`, SBCL-specific code kept in
`cl-support/`):
- an `IOError` condition model with catch/throw
- handles over Lisp streams
- argv, exit codes, `system`
- directory operations through `sb-posix`
- clock and CPU time
- the float predicates (`sb-ext:float-nan-p` and friends), with the
  float-trap behaviour still to be decided
- a mutable reference cell

**Existing bugs** to fix along the way:
- `prim.write-string-file` uses `:if-exists :overwrite`, which does not
  truncate (`runtime/io-primitives.scm:59,90`).
- `getEnv` does not handle an unset variable.

**Licensing.**  The H98 Report code and Hugs (BSD; its licence even
names the Yale Haskell Group) are safe to copy with their notices
kept.  **Do not copy from nhc98**: its licence is copyleft-ish, and its
libraries are C/GreenCard anyway.

## 4. Roadmap

Each milestone ends with the smoke and regression tests passing.

**M0 — Revival (done on `ng`).**  SBCL build, saved image,
`bin/yale-haskell`, smoke test.

**M1 — Modern repo and tooling** (§5).  *Done:* Makefile, out-of-tree
build directory, retired scripts, directory restructure, `.mumble`
sources.  *Remaining:* clean batch-mode errors and exit codes, fix the
warning noise, CI on Linux and macOS, a regression suite from
`examples/`, and a second host (ECL or ABCL).

**M2 — Cheap H98 wins (S each, parallelisable).**
- Lexer and parser:
  - hex/octal literals
  - reserved words
  - `-->`
  - H98 pragmas
  - `(,)` and the other built-in constructors
  - parenthesised LHS
  - `let` in comprehensions
  - `!` fields
  - local fixity declarations
- Static semantics:
  - drop the C-T rule
  - `(Integer, Double)` default
  - MR rule 2
  - synonym and partial exports
- Prelude:
  - additions that need no new language features (`Maybe`, `Either`,
    `Ordering`, `concatMap`, `seq`/`$!` via `strict1`, …)
  - port List, Char and Numeric
  - fix `isHexDigit` and `:overwrite`
- Lisp side: IO primitives (errors, handles), exposed through today's
  `thenIO`/`returnIO`.

**M3 — Constructor classes (XL, the critical path).**  New type
representation: type-variable heads or binary application.  Add a
kind-inference pass in `tdecl/`, a predicate-list context
representation with HNF reduction, partially applied instance heads,
and a new interface dump format.  Ship a minimal Functor/Monad Prelude
to exercise it.

**M4 — Monadic IO.**  Make `IO` abstract (newtype or primitive; keep
the `thenIO` tail-call optimisation), add `instance Monad IO`, desugar
`do` (including `fail` on match failure), and check
`Main.main :: IO t`.  Rebase `PreludeIO` on the Report.  Drop Dialogue,
or keep it as an optional compatibility module.

**M5 — Class hierarchy and deriving.**  Split Text into Show and Read,
remove Binary, add Bounded and the new Enum, regenerate the core
symbols, and update `derived/`.  Move Ratio, Complex and Array out of
the Prelude.

**M6 — `newtype`, then records.**

**M7 — Qualified names and the H98 module system.**  This can start
after M1 in parallel with M3–M6, but it touches every name lookup.

**M8 — System libraries.**  System, CPUTime, Directory, IO, Time,
Locale and Random.

**M9 — Remaining items.**  Polymorphic recursion, Unicode, and a
conformance pass against the Report (e.g. the Hugs test suite and
nofib's `imaginary` and `spectral` programs).

## 5. Repository restructuring and scripts

### 5.1 Done

- **Makefile.**  `make`, `make test`, `make clean`, `make ref`.  The
  Lisp drivers are in `tools/build/` (`compiler.lisp`, `prelude.lisp`,
  `image.lisp`).  The image is a standalone executable,
  `build/sbcl/yale-haskell`, wrapped by `bin/yale-haskell`, which sets
  the environment variables.  Logs go to `build/sbcl/logs/`.
- **Retired:** `haskell-setup` and `haskell-development` (csh with
  hard-coded Yale paths), all of `com/` (per-Lisp csh scripts and the
  RCS helpers), `bin/cmu-*`, the duplicate `bin/magic.scm`, and the
  stale `.elc` files.
- **Build output out of tree.**  `support/compile.scm` (now
  `src/mumble/compile.mumble`) maps `$Y2/<dir>/` to
  `$Y2/build/<lisp>/<dir>/`; `cl-init.lisp` does the same for the CL
  files; output files create their own directories.
- **Layout:**

  ```
  src/mumble/      the dialect (CL implementation + compilation-unit system)
  src/compiler/    top ast util printers parser import-export tdecl derived
                   prec depend type cfn flic backend csys command-interface
                   + system.mumble (loads everything)
  src/runtime/
  lib/haskell-1.2/ prelude hbc cl X11     (the H98 tree will sit beside it)
  examples/        demo tutorial
  tools/           build emacs
  doc/ tests/ bin/ ref/ build/
  ```

- **mumble made explicit.**  The 135 sources were renamed `.scm` →
  `.mumble`, `source-file-type` is `.mumble` (so generated `-hci` files
  are too), and `src/mumble/README.md` explains the dialect.
  `.gitattributes` classifies `.mumble` as Lisp on GitHub.
- **The 1.2 Prelude is kept** as `lib/haskell-1.2/prelude`.
- **Reference clones** of Hugs and the H98 Report live in the untracked
  `ref/` (`make ref`; see `ref/README.md`).

### 5.2 Remaining

1. **Tests.**  Grow `tests/smoke` into `tests/run/*.hs` with expected
   stdout, add `tests/fail/*.hs` for expected compile errors, port the
   `examples/demo` programs, and run everything in CI.
2. **Batch mode.**  Report compile errors cleanly and exit non-zero;
   silence the Lisp compiler's style warnings at run time (the
   deprecated `eval-when` names come from
   `src/mumble/cl-definitions.lisp`).
3. **Stop unlocking `COMMON-LISP`.**  Rename the definitions that
   redeclare CL specials, then remove `sb-ext:unlock-package`.
4. **Second host.**  ECL or ABCL: add their branches in `src/mumble/`
   and `LISP=ecl` support in the Makefile and `tools/build`.
5. **Language-version switch.**  When the H98 Prelude starts, put it in
   `lib/haskell98/`, and add a flag selecting which Prelude unit is
   loaded (`*prelude-unit-filename*` in
   `src/compiler/top/globals.mumble`).
6. **ASDF (later).**  `src/mumble/compile.mumble`'s unit system already
   records dependencies.  A generated `.asd` would let the compiler load
   into any Lisp with `(asdf:load-system :yale-haskell)`.
7. **Emacs.**  Update `tools/emacs/haskell.el` for the SBCL debugger
   prompt and drop the vendored `comint.el`.
8. **Docs.**  The `doc/` manuals exist only as `.dvi`/`.ps`; convert
   them to PDF and keep them as historical documentation.
9. **X11** (`lib/haskell-1.2/X11`): deferred; it could return via
   Quicklisp's CLX.

## 6. Open questions

- **Haskell 1.2 compatibility.**  Is it a goal (a `--haskell1.2` mode),
  or should the 1.2-isms simply be removed?  Answering this decides
  whether item 7 is worth the effort.
- **Inf/NaN.**  SBCL traps float overflow and division by zero by
  default.  H98 programs expect IEEE results, which probably means
  masking traps around generated float code.
- **IO error handling.**  It is not yet clear whether `catch` via a
  Lisp non-local exit interacts correctly with lazily produced input
  (`getContents`).
- **Cost of an abstract `IO`.**  The optimiser currently erases the
  `IO` plumbing because `IO` is a synonym.  It is not yet measured how
  much an abstract type costs.
- **Second host.**  ECL or ABCL first?  ECL has `ext:` POSIX support
  and C compilation; ABCL runs on the JVM, so it is the stronger
  portability test.

## 7. Status after the first Haskell 98 round (2026-10-05)

Test suite: **103 passed, 45 expected failures** (`make test`); CI in
`.github/workflows/ci.yml` (Ubuntu + macOS).

### Landed

- **Dialects.**  `lib/haskell98/` is built alongside `lib/haskell-1.2/`;
  `bin/yale-haskell --haskell98`.  Compiler-level differences are gated
  on `*haskell-dialect*` / `(haskell98?)` (`src/compiler/top/globals.mumble`).
- **Module lookup.**  `import M` finds a sibling `M.hs`/`M.hu` or
  `$HASKELL_LIBRARY/M.hu` without a unit file (`csys/compiler-driver.mumble`).
- **Syntax (M2).**  Hex/octal literals, `(,)`-style constructors,
  parenthesised function LHS, `let` in comprehensions, `!` fields, H98
  pragmas, `-->` operators (98 only), headerless `Main` (98 only), local
  fixity declarations.
- **Prelude.**  `Maybe`, `Either`, `Ordering`, `compare`, `Bounded`
  (no deriving), Enum's `succ`/`pred`/`toEnum`/`fromEnum`, RealFloat
  predicates, `seq`/`$!`, `concatMap` & co., Int-typed `take`/`drop`,
  H98 superclasses for Real/Integral, shortest-digit float `show`,
  `[1,2]` list syntax, tuple-pair arrays.  The Prelude no longer leaks
  non-H98 names into user scope (except the compatibility set listed in
  `lib/haskell98/README.md`).
- **Libraries.**  List, Char, Maybe, Numeric, Ratio, Complex, Ix, Array
  (Report code); System, CPUTime, Directory, Time, Locale, Random, and a
  standalone IO (handles, IOError, `catch`, `bracket`) with primitives
  in `src/runtime/{io-errors,system-prims,handle-prims}.mumble`.
  SBCL-only pieces are behind `#+sbcl` with fallbacks.
- **Tests.**  12 Haskell 1.2 demo regressions; H98 language tests by
  milestone; `.exit` (expected status) and `-j N` in the runner.

### Open bugs (each has a test, most as `.xfail`)

1. No defaulting under an expression signature:
   `show (2 ^ 2 :: Int)` is "ambiguous" (`default-in-annotation`).
   Also `round 2.5` (only `RealFrac`) is not defaulted (`default-realfrac`).
2. `Int` arithmetic wraps silently, and the default is `(Int, Double)`
   rather than `(Integer, Double)` (`default-integer`).
3. Monomorphism restriction rule 2: exporting a pattern binding reports
   "Can't export pattern binding" (`mr-exported`).
4. Shallow control stack: non-tail recursion over 100 000 elements
   overflows (`deep-stack`); consider a larger SBCL control stack for
   the image.
5. Batch mode: compiler diagnostics go to stdout; after a compile error
   it continues to "The variable #:|mainNNNN| is unbound"; and
   `apply-exec` prints an extra newline after every program
   (`command-interface/incremental-compiler.mumble:147`) — every
   `.stdout` currently includes it.
6. Datatype contexts (`data Eq a => Set a`) are not enforced.
7. `Assoc` and `Bin` are compiler core types, so H98 programs cannot
   define them (`prelude-names-free`).
8. A `foo.hs` beside a `Foo.hu` on a case-insensitive file system picks
   up the wrong unit file.
9. Possibly flaky: `tests/haskell-1.2/demo/prolog` failed once under
   `-j 8` right after a merge and has not reproduced since.

### Recommended next steps

- **Class layout in the runtime.**  `src/runtime/tuple-prims.mumble`
  hard-codes dictionary layouts (e.g. Ord = 6 methods + Eq at slot 6),
  which blocks making `compare` and `rangeSize` true methods
  (`ord-compare-method`).  Make tuple dictionaries generic, or
  per-dialect.
- **Deriving.**  `derived/ix-enum.mumble`: generate `fromEnum`/`toEnum`
  and drop Enum's Ord superclass (`enum-derived`); add `Bounded`
  deriving (`bounded-derived`); stop parenthesising nullary
  constructors in derived Text (`derived-show`).
- **System libraries follow-ups**, now that `Maybe`/`Either` exist:
  `ioeGetFileName`, `ioeGetHandle`, `try`, `BlockBuffering (Maybe Int)`;
  switch `Random` to `minBound`/`maxBound`/`realToFrac` and drop the
  compatibility names from the Prelude.
- **Unify I/O.**  When monadic IO lands (M4), the Prelude takes over
  `IO.hs`'s `IOError`, `ioError`, `userError` and `catch`, and Prelude
  I/O is rebuilt on the handle primitives.
- **M3 (constructor classes)** remains the critical path.
