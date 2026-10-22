# Plan: building MicroCabal

[MicroCabal](https://github.com/augustss/MicroCabal) (Lennart
Augustsson) is "a portable subset of the Cabal functionality".  Its
README: "A Haskell tool should be compilable by an implementation of
Haskell2010, which Cabal is definitely not."  It builds packages by
running a compiler (GHC or MicroHs) and fetches them with `wget` and
`tar`, choosing versions from Stackage.  That makes it the right first
real-world target: small, written for portability, and useful when it
works (it is how a Haskell implementation gets at Hackage).

A clone lives in `ref/MicroCabal` (gitignored;
`git clone --depth 1 https://github.com/augustss/MicroCabal ref/MicroCabal`).

## What it is (surveyed 2026-10-09, version 0.5.10.0)

- 15 modules, 2,746 lines.  `default-language: Haskell98` with
  `default-extensions: MultiParamTypeClasses ScopedTypeVariables
  PatternGuards`; `Text/ParserComb.hs` adds `FunctionalDependencies`.
- **Language beyond what we have:**
  - one multi-parameter class with a functional dependency,
    `class TokenMachine tm t | tm -> t` (Text/ParserComb.hs), with one
    instance, `TokenMachine LexState Char` (MicroCabal/Parse.hs), and
    instance contexts on it (`instance TokenMachine tm t => Alternative
    (Prsr tm t)`);
  - pattern guards (done, M11);
  - `forall` appears only in commented-out code, so ScopedTypeVariables
    is not needed yet;
  - trailing commas in export lists (Haskell 98 allows them; fixed
    2026-10-09).
- **"Modern base" classes:** `Functor`/`Applicative`/`Monad` instances
  for two parser types (`Prsr`, YAML's `Parser`), `Alternative`
  (`empty`, `<|>`, and its `many`/`some`/`optional`), `MonadFail`.
  123 uses of `<$>`, `<*>`, `*>`, `<|>`, `pure`.  Each Monad instance
  also defines `return`, which matters (below).
- **Library names used** (all small):

  | Module | Names |
  |---|---|
  | Data.Version | `Version(..)`, `makeVersion`, `showVersion`, `versionBranch` |
  | System.Directory | `doesFileExist`, `doesDirectoryExist`, `listDirectory`, `removeFile`, `getCurrentDirectory`, `setCurrentDirectory` |
  | System.Process | `callCommand` |
  | Control.Exception | `catch`, `try`, `SomeException` |
  | System.Environment | `getArgs`, `lookupEnv` |
  | System.Exit | `exitWith` |
  | System.Info | `os`, `arch` |
  | Text.Read | `readMaybe` |
  | Data.Function | `on` |
  | Debug.Trace | `trace`, `traceM` |
  | Data.List | `stripPrefix`, `isSuffixOf`, `partition`, `sortBy`, `(\\)`, `nub` (`stripPrefix` is base, not the 2010 Report) |
  | Control.Applicative | `Applicative(..)`, `Alternative(..)`, `<$>` |

## Strategy

Get to a running `mcabal` quickly, with any workaround **recorded as a
patch** in `tools/microcabal/` rather than edits to the clone, then
remove the patches one by one by implementing the feature properly.
The survey script `tools/microcabal/survey.sh` loads every module in
dependency order and prints the first error of each, which is the
progress meter.

### Step 1 — libraries (no compiler changes)

Add the modules above to `lib/haskell98/`:

- Data.Version, Data.Function, Debug.Trace, System.Info, Text.Read are
  plain Haskell (or one primitive).
- System.Directory and System.Process.callCommand are thin primitives
  over CL/SBCL (`directory`, `probe-file`, `delete-file`,
  `sb-ext:run-program "/bin/sh" -c`), in the style of ForeignPrims.hi.
- Control.Exception: `catch`/`try` over `SomeException`, catching both
  IO errors and Haskell runtime errors (`error`, pattern-match failure),
  which needs a primitive around the runtime's error signal.
- Control.Applicative and Control.Monad.Fail: see step 2.

Done when the survey gets past every `import`.

### Step 2 — the class hierarchy

Two ways:

- **(a) A compatibility layer on the Haskell 98 Prelude.**
  Control.Applicative defines `Applicative` (superclass `Functor`) and
  `Alternative`, with instances for IO, Maybe, [], Either e, (->) r;
  Control.Monad.Fail defines `MonadFail`.  Monad keeps no Applicative
  superclass.  This is enough for MicroCabal *if* every Monad instance
  defines `return` (true) and no code needs `Applicative` from a
  `Monad m =>` constraint.  Remaining gap: a refutable pattern in `do`
  calls the Haskell 98 `Monad(fail)`, not `MonadFail(fail)`, so a parser
  that relies on pattern-match failure in `do` would get an error
  instead of backtracking.  Check MicroCabal for that before relying on
  it.
- **(b) A modern-base Prelude** (Functor ⇒ Applicative ⇒ Monad,
  MonadFail, Semigroup/Monoid, Foldable/Traversable) as a new dialect
  or a Prelude option, with `do` desugaring through MonadFail.  This is
  what most real code assumes (see REAL-WORLD-TARGETS.md) but breaks
  Haskell 98 programs that define Monad without Functor, so it must be
  a switch, not a change to the Haskell 98 Prelude.

Do (a) now; (b) is the follow-on project once MicroCabal runs.

### Step 3 — multi-parameter classes with functional dependencies

The type checker's classes have one parameter everywhere: a context is a
(class, tyvar) pair (`context` struct, util/signature.mumble), and
dictionaries, instance lookup, context reduction, defaulting, deriving
and interface files all assume it.  Real support is a substantial
change; plan it as its own milestone:

1. Representation: class arity; a context is (class, types); instances
   keyed on the tycons of all parameters.
2. Dictionary passing is unchanged in principle (one dictionary per
   constraint).
3. Functional dependencies as *improvement*: when a constraint's
   determining parameters are known, unify the dependent ones with the
   matching instance's (this is what makes `TokenMachine LexState t`
   fix `t = Char`).
4. Defaulting and the ambiguity check must count a type variable as
   determined if a fundep determines it.

Meanwhile, **patch** `Text/ParserComb.hs` (tools/microcabal/): the only
instance is `TokenMachine LexState Char`, so the class can become
single-parameter in `tm` with the token type fixed, or the class can be
removed and its two methods made ordinary functions on `LexState`.

### Step 4 — compile and run mcabal

- `yale-haskell --haskell98 src/MicroCabal/Main.hs ARGS` runs it in the
  image; the module is named `MicroCabal.Main` (`-main-is`), so the
  driver needs a way to name the main module (an option, or a
  `Main.hs` wrapper in tools/microcabal/).
- Tests: `mcabal --version`, `mcabal help`, parsing a real `.cabal`
  file (MicroCabal's own), parsing a Stackage snapshot list.
- Then a saved executable (as bin/yale-haskell does for the compiler).

### Step 5 — a Yale Haskell backend for MicroCabal

MicroCabal has `Backend/GHC.hs` and `Backend/MHS.hs`.  A
`Backend/Yale.hs` would build a package by running `yale-haskell` on
its modules with the package's source directories on the search path
and install the compiled units somewhere a later compile finds them.
This needs, on our side: a package/library search path (`-i DIR`),
compiled units written to an install directory, and CPP (most Hackage
packages use `{-# LANGUAGE CPP #-}`).  This step is where
REAL-WORLD-TARGETS.md takes over.

## Progress

| Date | Survey result |
|---|---|
| 2026-10-09 | 1 of 15 modules loads (MicroCabal.Regex).  Fixed: trailing commas in export/import lists.  Next: step 1 libraries |
| 2026-10-09 | 4 of 14 load (Regex, YAML, Macros, StackageList) with `--modern-prelude`.  Done: step 1 libraries (Control.Exception, System.Directory/Process/Info, Data.Version/Function, Debug.Trace, Text.Read, lookupEnv; BasePrims.hi over src/base/base-runtime.lisp); step 2a (PreludeModern: Applicative, Alternative, MonadFail, Semigroup/Monoid; `--haskell2010`, `--modern-prelude`) |
| 2026-10-09 | 10 of 14 load.  Fixed: derived Show of a type with more than 6 constructors required Read (bffd7a4); System.IO gained openTempFile and the 2010 operations (505e867).  Blockers left are extensions, not Report gaps |

| 2026-10-10 | 14 of 14 load, and mcabal runs.  Done: pattern type signatures (9c98600); multi-parameter classes with functional dependencies (e19c23a, 9ffb5a5), so Text/ParserComb.hs is unpatched; base's Control.Monad for `--modern-prelude` (0c15ed4); tools/microcabal/mcabal.hs, a `Main` wrapper (b7d7efd); compiled units cached between runs (e8aa2aa): a cold run takes about 7 s, a warm one 0.3 s |

**Running it:**

    MHS=ghc bin/yale-haskell --haskell98 --modern-prelude tools/microcabal/mcabal.hu parse FILE.cabal

mcabal wants `$MHS` (or `mhs` on the path) at startup, even for `parse`.

**Step 4 results:** `--version`, `help` and `parse` agree with a GHC-built
mcabal on 19 `.cabal` files: MicroCabal's own, MicroHs.cabal, MicroHs's
base.cabal, Hugs's Cabal.cabal and nhc98's 15 library packages.
- 14 files parse identically.
- Five (nhc98's base, Cabal, containers, directory and process) use `{ }` blocks after `if`, which MicroCabal does not parse. Both
  builds report the same parse error.
  - Yale's stdout also has the partial line printed before the error.
    GHC's block-buffered `hPutStr` discards a partly written string when
    an exception interrupts it. Haskell does not specify either way.

**Next:**
1. A Stackage snapshot list (`mcabal` with a `snapshot` file) and the
   `build` / `install` commands, which run `$MHS`: try with `MHS=ghc`.
2. A saved executable for mcabal. The unit cache already removes most
   of the startup time.
3. Step 5.

## Step 5 — the Yale backend (2026-10-17, 3.0.2.0)

`tools/microcabal/` holds the backend and how it is put into MicroCabal
without editing the clone:

- `Yale.hs` is `MicroCabal.Backend.Yale`; `yale-backend.patch` makes
  MicroCabal.Main offer it as `--yale`, the default;
- `setup.sh` copies `ref/MicroCabal/src` to `build/microcabal/src` and
  applies both, and `mcabal` runs that copy (re-running setup.sh when a
  source is newer): `tools/microcabal/mcabal install PKG`.

A package is installed as its sources, in the package database
`$CABALDIR/yale-VERSION/packages` that `--package-db` reads
(src/compiler/csys/packages.mumble): `NAME-VERSION/src` (every
hs-source-dirs tree and the Paths_ module), `include/`, and
`yale-package` (default-language and default-extensions, cpp-options,
include-dirs).  Building compiles a module that imports every exposed
and other module; installing copies the directory and compiles again
there, so the unit cache holds the installed paths.  An executable is a
script running its main module with yale-haskell.

- The packages Yale's library provides count as installed: base,
  containers, text, bytestring, mtl, transformers, parsec, ... (the
  list is `builtinPackages`), and template-haskell, which packages
  depend on for code only GHC compiles.
- Modules with `{-# LANGUAGE TemplateHaskell #-}` or QuasiQuotes are
  installed but not compiled (tagged exposes Data.Proxy.TH beside
  modules that need no TH).
- `impl(ghc ...)` conditions are false (the compiler is `yale`), and
  `__GLASGOW_HASKELL__` is not defined, as before.

`tools/microcabal/hackage-survey.sh` installs a list of 43 popular
libraries with `-r` (into `build/mcabal` unless `$CABALDIR` is set) and
prints the first error of each.

### First survey (2026-10-17): 2 of 43 build

split and splitmix build, install and run (`Data.List.Split` from a
program with `--package-db`).  The rest stop at the first of these;
fixing one usually moves several packages to their next error:

| Gap | Packages stopped by it |
|---|---|
| `module M () where`: an empty export list does not parse | base-orphans (so semigroupoids, profunctors), transformers-compat (transformers-base, mmorph) |
| `instance Bifunctor Const` missing | assoc (strict, either, bifunctors, lens) |
| Template Haskell in an exposed module (now skipped, see above) | tagged (comonad, distributive, free) |
| nullary constraint `Partial =>`; `a ~ b` with others; `(MonadThrow m, ...)` forms in contexts | safe, StateVar (contravariant), exceptions (aeson) |
| `Text.Read` does not export `Read`; `Data.Coerce` does not export `Coercible` | megaparsec, case-insensitive, indexed-traversable |
| modules: GHC.Stack, Data.Functor.Classes, Data.ByteString.Short, GHC.Arr, GHC.IO, Foreign.C.ConstPtr | call-stack (HUnit), data-fix, these, utility-ht, attoparsec, data-default |
| `liftA2` is not an Applicative method | parser-combinators |
| `{-# INLINE [0] f #-}` phase control | microlens |
| `#error` unless `__GLASGOW_HASKELL__` | dlist |
| a GHC boot package not on Stackage's list (integer-gmp); C headers (MachDeps.h) | integer-logarithms, primitive (vector) |
| others: a GADT-style record parse (prettyprinter, optparse-applicative), an existential with `deriving` after `#if` (async), a too-general signature (colour), base-compat's forkOSWithUnmask, ansi-wl-pprint | one each |

### Executables (2026-10-17, 3.0.5.0)

The backend builds an executable with `yale-haskell build`, a
standalone executable, and installs it in `$CABALDIR/bin`.  alex
3.5.4.2 (`mcabal -r install alex`) builds and generates the same
scanners as a GHC-built alex on all 46 grammars of its tests/ and
examples/ (44 identical outputs, the same 2 errors).  It needed:

- `$YALE_CPP_OPTIONS=-D__GLASGOW_HASKELL__=906`: Happy's generated
  parser in alex has `#error This code isn't being built with GHC`.
  Yale Haskell does not define `__GLASGOW_HASKELL__` by default (so that
  libraries choose their portable code); the variable adds options to
  every package the backend stages;
- `import Data.List.NonEmpty (pattern (:|))`, `import GHC.Exts
  (Int(I#), ...)`, `#include "ghcconfig.h"`, DatatypeContexts with
  `default-language: Haskell2010`, and OverloadedLists in a local
  binding (all fixed in 3.0.5.0).

hscolour does not get that far: MicroCabal itself (built by GHC as well)
rejects its cabal file's empty `Default-Extensions:` field.

### Second survey (2026-10-17, 3.0.6.0): 6 of 43 build

split, safe, base-orphans, splitmix, assoc and call-stack build.  Each
of the others stops later than before; most now at a missing module:

| Gap | Packages stopped by it |
|---|---|
| Data.Bifoldable (and Bitraversable) | tagged, so comonad, bifunctors, distributive, profunctors, free, semigroupoids, either, lens |
| Data.ByteString.Short | these, strict |
| Control.Applicative.Lift (transformers) | transformers-base, mmorph |
| Text.Read's readPrec (ReadPrec) | megaparsec, case-insensitive |
| GHC.List, GHC.Arr, GHC.IO, Control.Monad.ST.Unsafe, Foreign.C.ConstPtr, Data.Hashable.Lifted, System.Clock (clock is C) | indexed-traversable, utility-ht, attoparsec, aeson, data-default, data-fix, extra |
| an exported qualified name (`C.choice` in Control.Monad.Combinators) | parser-combinators |
| a rank-N type synonym (`type Traversal s t a b = forall f. ...`) crashes | microlens |
| "Execution of a form compiled with errors" (generated Lisp) | StateVar, contravariant |
| the kind `TYPE` | primitive, vector |
| `E.Handler` from a qualified import; `forkOSWithUnmask`; integer-gmp; a signature too general (colour; prettyprinter's `Doc ann` with Void) | HUnit, base-compat, integer-logarithms, colour, prettyprinter, optparse-applicative |

### Third and fourth surveys (2026-10-17, 3.0.7.0 and 3.0.8.0): 9, then 11 of 43

Built: split, safe, base-orphans, splitmix, assoc, parser-combinators,
utility-ht, call-stack, HUnit, prettyprinter, optparse-applicative.
3.0.7.0 and 3.0.8.0 fixed what the second survey found (qualified names in
export lists, polytype synonyms, the empty layout block, extensible
exceptions, explicit Prelude import lists, eight modules); 3.0.9.0 adds
the small modules the fourth found (Data.Bifoldable1 for tagged and the
eight packages above it, Data.Functor.Contravariant, Control.Monad.Trans
.Select).  What is left is larger:

| Gap | Packages |
|---|---|
| ReadPrec as a method of Read (readPrec in instances) | megaparsec, case-insensitive |
| GHC.Generics' Rep and the representation types | data-default, indexed-traversable |
| GHC.IO's IO constructor (State# RealWorld) | async, attoparsec |
| the kind TYPE, unboxed primitives | primitive, vector |
| Template Haskell (Language.Haskell.TH.Syntax) | exceptions, so aeson |
| `__GLASGOW_HASKELL__` checks (`YALE_CPP_OPTIONS` works around) | dlist |
| binary's Builder needs Data.ByteString.Builder.Prim | these, strict |
| C libraries (clock), boot packages (integer-gmp), Data.Hashable.Lifted | extra, integer-logarithms, data-fix |
| type checking: a signature too general (colour, microlens) | colour, microlens |


### Agda's dependency chain (2026-10-18 to 2026-10-22, 3.0.15.0 to 3.1.0.0 and after)

`tools/microcabal/mcabal -r install Agda` (Agda 2.8.0.2), run into
`build/mcabal`, now installs every library Agda depends on, about 80
packages (`build/mcabal/yale-VERSION/packages`), among them aeson,
async, vector, primitive, bifunctors, profunctors, semigroupoids,
comonad, generic-data, generic-deriving, ListLike, regex-tdfa, zlib,
pqueue, nonempty-containers, monad-control, process-extras,
vector-hashtables, happy's libraries and alex.  About twenty need a
patch or cpp options in `tools/microcabal/patches/` (a GHC-only
construct replaced by portable code).

What the chain needed is in CHANGELOG.md (3.1.0.0 and the unreleased
entries): GHC.Generics' representation, GHC.Exts' primops threaded by
State#, GADT refinement, equality superclasses and given equalities on
type families, constraint families, Coercible, ImplicitParams,
ApplicativeDo, MonoLocalBinds, mutually recursive modules,
`yale-hsc2hs` for `.hsc` sources (zlib), and many library modules.

Agda itself is being compiled; Agda.Setup and Agda.VersionCommit (Template
Haskell) are installed without being compiled.  Agda counts as done when
its own test suite passes and it checks agda-stdlib
(REAL-WORLD-TARGETS.md, "Agda").
