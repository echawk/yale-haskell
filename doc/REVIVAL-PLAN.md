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

**M10 — Command line and interactive system (planned 2026-10-08).**
Today `bin/yale-haskell` is a shell wrapper around an image saved by
`tools/build/image.lisp`, and the interactive system is the 1993
command interface: definitions go into an "extension" that `:eval`
compiles, expressions cannot be typed at the prompt, and options are
`:p=`-style commands.  Plan:

- *Executable.*  An ASDF system `yale-haskell/cli` (plain CL, not
  mumble) whose `program-op` builds the executable with
  `uiop:dump-image`/`save-lisp-and-die` and an `:entry-point`,
  replacing `image.lisp` and most of the shell wrapper.  Lisp
  dependencies are installed with ocicl (`ocicl install clingon`).
- *Arguments* with clingon: `yale-haskell run FILE [-- ARGS]` (also
  the bare `yale-haskell FILE` the test runner uses), `repl [FILES]`,
  `compile UNIT`, and options `--dialect`, `--backend flic|grin`,
  `--printers`, `--no-optimize`, `--profile`.
- *REPL*, GHCi-like on top of the incremental compiler: an expression
  is evaluated and shown (`show`, or run if it is an `IO` action);
  `:type`, `:load`, `:reload`, `:browse`, `:module`, `:set`,
  `:quit`, multi-line `:{ … :}`, and definitions at the prompt.  An
  expression becomes an extension binding (`it = expr`) whose type
  decides print vs run.  Line editing and history through a small CL
  line editor, or `rlwrap` as a documented fallback.
- *Keep:* one image per dialect, batch-mode output and exit codes
  (tests/run-tests), the old command interface reachable during the
  transition.

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

## 8. Long-term direction (sketch)

Goals beyond Haskell 98, recorded early so that near-term work does not
rule them out.  None of this should start before M9; the point is
to shape design decisions now.

**North star:** a *reasonably* fast Haskell on Common Lisp that is a joy
to work on.

### 8.1 Portability across Lisp implementations

SBCL stays the main host, but ECL and ABCL should be supported as well.
The code base predates most implementation-specific idioms, so this
should be cheaper than for most CL projects.

- Keep all non-standard calls behind one layer (`src/mumble/` and the
  `#+sbcl` primitives in `src/runtime/`); no new bare `sb-ext:` /
  `sb-sys:` calls anywhere else.
- Add a CI job per host once one builds: first the smoke test, then
  `make test`.  ECL is the easier first target (POSIX, C compilation);
  ABCL is the stronger portability test (§6).
- Known friction points: saved images (`save-lisp-and-die` versus ECL's
  executables versus ABCL jars), float traps (Inf/NaN, §6), control-stack
  size (bug 4), and file system and `run-program` primitives.

### 8.2 Parser: reuse a standard grammar

Today's lexer and parser are hand-written recursive descent
(`src/compiler/parser/`, about 3.6k lines), extended piece by piece for
M2.  Longer term, a grammar-driven front end would be smaller and easier
to keep in line with the Report.

- **Candidate source:** the Hugs H98 yacc grammar (`parser.y`), or
  the Report's own grammar (Report §9/§10).  Layout is handled
  outside the grammar (Hugs does it in the lexer; the Report uses the
  L function), so we would keep or rewrite the layout algorithm
  regardless.
- **Questions to answer:**
  - Can a CL LALR generator (e.g. `cl-yacc`) take the Hugs
    productions close to verbatim, with Lisp semantic actions that build
    our existing `ast/` structs?  That gives the smallest grammar for the
    least work.
  - PEG parsers (`esrap`) produce good parsers but need the grammar
    restructured by hand; only worth it if the LALR route stalls.
  - Licensing of the Hugs grammar (BSD-style; check before copying).
- **Approach:** prototype on expressions only, behind a flag, and diff
  the ASTs against the current parser over `tests/` and `lib/`.
  Switch over only when both agree everywhere.  Operator precedence stays
  in `prec/` (fixity is resolved after parsing in both designs).
- Every new language feature added before then (M3–M7) should keep the
  parser change small and test-covered, so it can be carried over.

### 8.3 Performance: keep it profilable

Performance was reportedly part of why the original project was
abandoned.  It is **not** to be tackled now, but nothing should make it
harder to measure later.

- Generated Lisp should keep readable, stable names (Haskell
  module + identifier) so that `sb-sprof` and `sb-profile` output can be
  mapped back to source.  Do not over-`gensym` new code.
- Keep the runtime representation choices (thunks, dictionaries, `IO`)
  each behind a small set of macros, so they can be swapped and measured
  in isolation.
- Add a small benchmark set early (nofib `imaginary`, the 1.2 demos)
  and record timings in CI as numbers, not pass/fail, so regressions show
  up.
- Candidate later work: extend the existing strictness and boxing
  passes (`backend/strictness.mumble`, `backend/box.mumble`), unboxed
  `Int`/`Double` paths, dictionary specialisation, cheaper thunks, and a
  per-module `(declare (optimize ...))` policy.

### 8.4 Haskell 2010 and beyond

Only after H98 works, but keep the design open.

- H2010 is a small delta from H98: hierarchical module names, FFI,
  pattern guards, `EmptyDataDecls`, relaxed dependency analysis, no
  n+k patterns, and the
  `Data.*`/`System.*`/`Foreign.*` library layout.
- **Design constraints for now:**
  - module names should be treated as dotted strings, not single
    symbols (affects M7 and the `.hu` search path);
  - the dialect switch (`*haskell-dialect*`) should take a third value
    rather than becoming a boolean;
  - `lib/` layout should be able to hold a `haskell2010/` tree.
- **References to borrow from:**
  - the Haskell 2010 Report (library code is given in the Report, as for
    H98);
  - Hugs (Sept 2006), which implements most of H2010's pieces in C and
    Haskell and ships `base`-style libraries;
  - older GHC releases (6.x) and the `base` package for library source;
    `haskell-src` / `haskell-src-exts` for grammar coverage;
  - nhc98 / yhc, which are smaller and more readable than GHC (read
    only; see the licence note in `ref/README.md`).
- FFI: on CL this means mapping `foreign import ccall` to CFFI, which
  also helps portability (§8.1).

### 8.5 Haskell 1.3 and 1.4 as dialects

Haskell 1.3 (1996) and 1.4 (1997) sit between the two dialects we already
have, so they can share almost all of the compiler.  The Reports and
change summaries are in `ref/haskell-1.x/`; a 1.4 implementation (GHC
3.02) is in `ref/ghc-3.02/` (see `ref/README.md`).

**Key observation.**  Almost all of the difference between 1.2 and 98
comes in at 1.3: constructor classes, monadic IO and `do`, Read/Show
replacing Text, field labels, `newtype`, strictness annotations,
qualified names, the relaxed C-T rule, standard libraries, and a smaller
Prelude.  So M3–M7 *are* the 1.3 work.  1.3→1.4 and 1.4→98 are each a
handful of small changes:

| Feature                               | 1.2 | 1.3 | 1.4 | 98 |
|---------------------------------------|-----|-----|-----|----|
| Constructor classes, monadic IO, `do` | –   | ✓   | ✓   | ✓  |
| Text class (vs. Read/Show)            | ✓   | –   | –   | –  |
| Dialogue/continuation IO              | ✓   | –   | –   | –  |
| Import renaming, `M..` exports, interface files in the language | ✓ | – | – | – |
| `Eval` class (`seq :: Eval a => …`)   | –   | ✓   | ✓   | –  |
| `MonadZero` / `MonadPlus`; `do` failure uses `zero` | – | ✓ | ✓ | – (`fail`) |
| Monad comprehensions                  | –   | –   | ✓   | –  |
| Field punning                         | –   | ✓   | –   | –  |
| Import/export of a *subset* of constructors or methods | – | – | ✓ | ✓ |
| `Ord` superclass of `Enum`            | ✓   | ✓   | –   | –  |
| Defaulting applies to MR-restricted variables | – | – | ✓ | ✓ |
| Character set                         | ASCII | ISO-8859-1 | Unicode | Unicode |

(Built from `from12to13.html` and `from13to14.html`; check each row
against the Reports before implementing it.)

**Strategy.**

1. **Dialects become an ordered list**, `haskell-1.2 < haskell-1.3 <
   haskell-1.4 < haskell98 (< haskell2010)`.  Replace `(haskell98?)`
   (7 uses today, in `top/globals`, `parser/lexer` and
   `parser/module-parser`) with named *feature predicates*, e.g.
   `(feature? 'constructor-classes)`, `(feature? 'eval-class)`, defined
   in one table in `top/globals.mumble` as dialect ranges.  A gate
   then reads as the feature it is about, and a new dialect is one new
   column, not a hunt through the source.
2. **Features are built once, behind predicates, in whichever version
   introduced them.**  M3–M7 land as 1.3 features that 1.4 and 98
   inherit.  The few features that exist only in 1.3/1.4 (Eval,
   MonadZero, monad comprehensions, punning) are small desugarings or
   Prelude classes and should be cheap once the features they build on
   exist.
3. **Most differences live in `lib/<dialect>/`, not the compiler.**
   Text vs. Read/Show, the Enum superclass, `>>=` fixity, Eval and
   MonadZero are Prelude declarations.  The compiler only has to stop
   hard-wiring the Prelude's shape: core symbol tables, derived
   instances (`derived/`) and runtime dictionary layouts
   (`runtime/tuple-prims.mumble`, see §7) must be looked up by name
   from the Prelude rather than assumed.  This is the same work §7
   already lists for H98 and pays off for every dialect.
4. **Library trees.**  `lib/haskell-1.4/` starts as a copy of the 1.4
   Report code (`standard-prelude.html` plus the library Report), the
   same way `lib/haskell98/` was built from the 98 Report.  1.3 then
   comes from 1.4 with the changes undone (Ord ⇒ Enum, no monad
   comprehensions, punning).  To share code, factor common modules
   later (e.g. `lib/common/`), but only once there are two working
   trees to compare.
5. **Tests.**  `tests/haskell-1.3/` and `tests/haskell-1.4/`, one
   test per table row, run with `--haskell1.3` / `--haskell1.4`.  The
   same program run under adjacent dialects (e.g. a monad comprehension
   accepted by 1.4 and rejected by 98) is the cheapest check that a
   gate is in the right place.

**Ordering.**  Nothing here changes the critical path: do M3 (constructor
classes) and M4 (monadic IO) first, as 1.3 features.  Then, in order:

- introduce the feature table;
- bring up `lib/haskell-1.4/` (closest to 98, so the most shared code);
- add 1.3 last.

1.3 and 1.4 should not delay H98, but every feature from M3 on should be
written with its first dialect in mind.

**Open points.**
- The 1.3 Library Report is not on haskell.org; look in the Wayback
  Machine (`haskell.cs.yale.edu/haskell-report/library.html`) or in
  Hugs 1.3 / GHC 2.x distributions.
- Should 1.2 also gain the shared features under a flag, or stay frozen
  as the original system?  Frozen is simpler and keeps the 1.2 demos as
  a fixed regression baseline.

### 8.6 Coalton: a reference type checker, and a possible target

[Coalton](https://github.com/coalton-lang/coalton) (MIT licence) is a
statically typed, Haskell-like language embedded in Common Lisp.  Its
type checker is reported to follow Jones's *Typing Haskell in Haskell*
(THIH); **verify this in its repository before relying on it**.  Two
uses:

1. **A source of truth for the type checker.**  THIH is the reference
   description of Haskell 98 type inference: kinds, type classes,
   defaulting, the monomorphism restriction and binding groups.  A
   maintained CL implementation of it is a useful cross-check for
   `src/compiler/type/`, which predates THIH and has no kind inference
   (STRATEGY LG-CCONSTRUCTOR).  Possible uses, cheapest first:
   - read its kind inference and binding-group handling when doing kind
     inference and polymorphic recursion (M9);
   - port THIH-derived test cases as Yale tests;
   - (more work) run both checkers on the same programs and compare the
     inferred types.  This needs an AST bridge, so only if the cheaper
     options leave real doubt.
   Copying code needs attribution under its licence (see "Licensing" in §3).
2. **Emitting Coalton instead of plain CL (experiment).**  After type
   checking we know every binding's type, so a back end could emit
   Coalton.  Coalton would then re-check the translation (a form of
   translation validation) and supply its own dictionary passing and
   optimisations.  Caveats to settle first:
   - Coalton is **strict**: laziness would have to be explicit in the
     emitted code (thunks as data, `force` calls), which is exactly what
     the GRIN-style IR makes explicit (doc/EVAL-APPLY-GRIN.md §5).  So
     GRIN, or FLIC after box analysis, is the natural input for such a
     back end, not the typed front-end AST;
   - the type systems differ in places (defaulting, the monomorphism
     restriction, class hierarchy details), so emitted code should carry
     explicit types rather than rely on Coalton's inference;
   - it adds a dependency (now loadable: ASDF-PORTING.md) and ties
     generated code to Coalton's runtime representation.
   Treat it as an experiment beside the Lisp back end, not a replacement.
   Do it after GRIN P4, when there is an explicit IR to translate from.

## 9. Status after the constructor-class / monad round (2026-10-06)

Test suite: **141 passed, 15 expected failures** (`make test`).

### Landed (branch `constructor-classes`, which includes the `cheap-wins` merge)

- **Constructor classes (M3).**  `tyapp`/`ntyapp` types: a type variable
  may be applied; unification binds the head to a partially applied tycon
  (`unify-app-con`, `unify-apps`); constraints on `f a` wait on the head
  variable (`ntyvar-app-contexts`) until it is instantiated; instance heads
  may be partial (`Maybe`, `Either e`, `(->) r`, `[]`).  No kind inference:
  a kind mismatch shows up as an arity/unification error.
- **`do` (M4).**  Lexed under `(feature? 'do-notation)`, desugared in the
  scope phase (`prec/scope.mumble`): failure-free patterns use `>>=` with a
  lambda, others go through `case` with `fail` (98) or `zero` (1.3/1.4).
- **`newtype`.**  Erased in `ast-to-flic` and in cfn pattern matching
  (`algdata-newtype?`).  Deriving works unchanged.
- **Monadic IO.**  `IO` is a newtype over the state-passing representation
  (the core symbol `IO` is created as a data type when the dialect has
  `newtype`); `instance Monad IO`; `IOError`, `ioError`, `catch`,
  `putStr`... live in `PreludeIO`; `IOPrims.hi` moved into the Prelude.
  The 1.2 Dialogue names that clash (`readFile`, `getArgs`...) are gone
  from the H98 Prelude; `appendChan`, `stdout`, `done`... remain as
  compatibility.
- **Dialect feature table** (`top/globals.mumble`): ordered dialects
  `haskell-1.2 < 1.3 < 1.4 < haskell98`, `(feature? 'name)`.  Features
  `show-read` / `show-method` exist but are not used yet.
- Everything from `cheap-wins` (defaulting, batch mode, deriving
  Enum/Bounded, C-T rule, partial exports, float traps, 512 MB stack).

### Unfinished: Show/Read split (M5), then Haskell 1.4

Compiler groundwork is in (core classes `Show`/`Read`, tuple dictionaries
`tupleShowDict`/`tupleReadDict`, derived Show/Read, generic Ix tuple
dictionary) but the Prelude still has `Text`.  Next steps:

1. Rewrite `lib/haskell98/prelude` (`PreludeCore`, `PreludeText`,
   `PreludeTuple` (`tupleShow`), `PreludeArray/Ratio/Complex/IO`, the
   libraries and tests) from `Text` to `Show` + `Read`; drop `Binary`/`Bin`;
   `Num` and `Ix` lose their `Text` superclass.  Re-enable the `show`
   method (it cannot be a core symbol: 1.2 defines `show` as a function).
2. `lib/haskell-1.4/`: Report Prelude (`Functor(map)`, `MonadZero`,
   `MonadPlus((++))`, `Eval`, `>>=` infixl 1, `filter`/`concat` generalised),
   `--haskell1.4` in `bin/yale-haskell`, `DIALECTS` in the Makefile.
   Compiler side: `Eval` contexts ignored, monad comprehensions (feature
   `monad-comprehensions`, translation in Report 3.11).
3. Records (M6), qualified names (M7); then 1.3 from 1.4.
