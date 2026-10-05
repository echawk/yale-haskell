# Yale Haskell revival plan

Status: exploratory (October 2026).  This document records where the
system stands, how far it is from Haskell 98, and the work needed to
get there.

## 1. Where we are

The source is Yale Haskell **Y2.0.5** (1994).  It implements **Haskell
1.2**, written in "mumble", a Scheme-like dialect hosted on Common Lisp
(`cl-support/`).  It last built on CMU CL 16f, Lucid, Allegro,
LispWorks and AKCL, all on SPARC.

**It runs again.**  On the `ng` branch the compiler, the Prelude and a
saved image build under **SBCL 2.6.9 on arm64 macOS**:

```
com/sbcl/compile          # ~117 Lisp files; style warnings only
com/sbcl/build-prelude    # full Prelude through every phase, to native code
com/sbcl/savesys          # bin/sbcl-haskell.core (~45 MB)
bin/yale-haskell foo.hs   # compile + run Main.main
bin/yale-haskell          # the old ":load / :run / =expr" REPL
tests/run-smoke           # output-comparison smoke tests
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

1. **Single supported host: SBCL** (fast native code, actively
   maintained, has `sb-posix` for the H98 system libraries).
   Optionally keep CCL/ECL building for portability.  Delete the
   Lucid, Allegro, LispWorks, AKCL, WCL, MCL and T branches.
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

**M1 — Modern repo and tooling** (§5).  Makefile, out-of-tree build
directory, delete dead hosts, clean batch-mode errors and exit codes,
fix the warning noise, CI on Linux and macOS, regression suite from
`progs/`.

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

### 5.1 Scripts to rewrite, retire or keep

| Today | Action |
|---|---|
| `haskell-setup`, `haskell-development` (csh, hard-coded Yale paths `/cs/licensed/...`) | **Retire.**  Replace with `com/sbcl/env.sh` (done) and later the Makefile.  No user should need to source anything. |
| `com/{cmu,lucid,allegro,lispworks,akcl}/*` (csh heredocs into a Lisp) | **Delete** (kept in git history).  `com/sbcl/{compile,build-prelude,savesys,clean}` replace them (done, POSIX sh). |
| `com/clean`, `com/locked`, `com/lookfor`, `com/unchecked` (RCS workflow) | **Delete.**  Git covers them. |
| `bin/cmu-haskell`, `bin/cmu-clx-haskell` | **Delete.**  Replaced by `bin/yale-haskell` (done). |
| `com/*/build-xlib`, `savesys-xlib`, `progs/lib/X11` | **Defer.**  Could come back via Quicklisp's CLX, but low priority. |
| `cl-support/wcl-patches.lisp`, `#+lucid`/`#+allegro`/… branches, T references in `README` and `com/clean` | **Delete** once SBCL is the only host, or keep one second host (CCL) for honesty. |
| `cl-support/PORTING`, `README`, `com/README` | **Rewrite** for the new build. |
| `emacs-tools/haskell.el`, `comint.el` (+ stale `.elc`) | Update `haskell.el` for the SBCL debugger prompt (PORTING step 8), drop the vendored `comint.el`, and drop the `.elc` files. |
| `doc/*` (`.dvi`/`.ps` only, no sources except a `.tex` in `progs`) | Keep as historical docs, converted to PDF.  Write a new user README. |

### 5.2 Layout and build changes

1. **Build output out of the source tree.**  Today every source
   directory grows a `<lisp>/` subdirectory, which is why the scripts
   need `make_bin_dirs` and `.gitignore` needs `sbcl/`.  Change
   `compile.binary-subdir` (`support/compile.scm:22`), the
   `*support-binary-directory*` in `cl-support/cl-init.lisp` and
   `PRELUDEBIN` so that everything goes under `build/sbcl/<dir>/`.
   This is a small change and removes most of the script complexity.
2. **Top-level `Makefile`** (`make`, `make prelude`, `make image`,
   `make test`, `make clean`) that wraps `com/sbcl`, with real
   dependencies on the `.scm`/`.hs` sources.
3. **Directory regrouping (optional, one mechanical commit).**  The 20
   top-level directories could become:

   ```
   host/        cl-support (+ support/: mumble utilities, unit system)
   compiler/    top ast util printers parser import-export tdecl derived
                prec depend type cfn flic backend csys command-interface
   runtime/
   lib/         prelude/  (was progs/prelude)
                hbc/ cl/ X11/ (was progs/lib)
   examples/    progs/demo, progs/tutorial
   tools/emacs/
   doc/  tests/  bin/  com/sbcl/ (or scripts/)
   ```

   Each unit file hard-codes `"$Y2/<dir>/"` (e.g.
   `parser/parser.scm:8`), as do `support/system.scm` and the `.hu`
   files under `$PRELUDE`.  A move is therefore a sed over about 25
   unit files plus `system.scm`.  Worth doing only together with item 1.
4. **ASDF (later).**  `support/compile.scm`'s unit system already
   records dependencies.  An `.asd` generated from it would let the
   compiler load into any SBCL with `(asdf:load-system :yale-haskell)`.
   It is not needed early.
5. **Stop unlocking `COMMON-LISP`.**  Find the definitions that
   redeclare CL specials and rename them, then remove
   `sb-ext:unlock-package`.
6. **Tests.**  `tests/smoke` (done) grows into `tests/run/*.hs` with
   expected stdout; `tests/fail/*.hs` checks for expected compile
   errors; and an H98 conformance directory.  Run them all in CI.
7. **Language-version switch.**  While the H98 work is in progress,
   keep the 1.2 Prelude under `lib/prelude-1.2/`, and add a flag that
   selects which Prelude unit is loaded.  The 1.2 demos and the
   tutorial then keep working as regression tests until they are
   ported.

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
- **Second host.**  Should CCL be kept building, as a guard against
  SBCL-isms creeping into the mumble layer?
