# Plan: KiCS2, the Kiel Curry System, on Yale Haskell

Status (2026-10-23): steps 1-3 done, step 4 under way.
- curry-frontend builds with MicroCabal's Yale backend (from the
  `frontend` submodule, `tools/microcabal/mcabal -r install`; set-extra,
  tree-monad and parallel-tree-search come from Hackage, Stackage lacking
  them), and the Yale-built executable writes the same FlatCurry,
  interface and icurry files as the distribution's kics2-frontend.
- The runtime builds as a package (`tools/conformance/kics2/setup.sh`).
- QuantifiedConstraints are implemented.
- The 58 generated modules compile; the Yale-built `kics2c`
  (`build/kics2/kics2c/kics2c`) with the Yale-built frontend writes the
  same Haskell, FlatCurry and info files as the distribution's for
  library modules (Data.List) and for the Curry Prelude.  The Prelude
  takes 77 s and 6.4 GB resident (GHC's build: 24 s, 5.0 GB).  It
  exhausted a 16 GB heap until instance dictionary functions kept their
  recent results: kics2c rebuilt `Curry [a]` and `Curry (a, b)`
  dictionaries on every call while reading the 3.9 MB annotated FlatCurry
  back, and kept millions of them live.
- Curry programs run: `tools/conformance/kics2/libs.sh` compiles the
  library (29 modules) with the Yale-built kics2c and frontend and
  installs it as the package `kics2-libs`; `run-curry.sh DIR MODULE
  [GOAL]` compiles a program against it and runs its main or prints a
  goal's values.  Of the 36 benchmarks in `benchmarks/suite` with a
  main: 15 give their results (Queens 2680, Primes 17393, PermSort,
  Tak, SearchEmbed, ...); 8 are older Curry the frontend rejects
  (no Eq context, `Success`); 6 import modules KiCS2 3 no longer has;
  NDNums and BFSvsPar loop under depth-first search, as their comments
  say; LogBindTest's main takes arguments; SearchSMM exhausts a 16 GB
  heap: the depth-first search keeps millions of unevaluated choice
  thunks live.  KiCS2's testsuite needs curry-check (a CPM package,
  not in the distribution).
Survey of 2026-10-22 below.  KiCS2 3.5.0 (upstream
<https://github.com/curry-language/kics2>, with its `frontend` submodule
<https://github.com/cau-placc/curry-frontend> at 66db010) and the arm64
macOS distribution `kics2-3.5.0-arm64-darwin.tar.gz` from
<https://www.curry-lang.org/kics2/download.html>, both in `ref/`
(untracked).

## What KiCS2 is

KiCS2 compiles Curry, a functional logic language (Haskell's syntax and
type classes, plus nondeterministic functions, free variables and
unification), into Haskell, and runs the result with GHC.  It has four
parts:

| Part | Written in | Size | Role |
|---|---|---|---|
| curry-frontend | Haskell (Haskell 2010, a few extensions) | 110 modules, 39,000 lines | `kics2-frontend`: parses and checks Curry, writes FlatCurry and interfaces |
| the runtime | Haskell (`runtime/`, plus the `idsupplyioref` IDSupply) | 17 modules, 3,200 lines, and the Hackage packages tree-monad and parallel-tree-search | choice IDs, search strategies, the `Curry` class's machinery |
| the compiler `kics2c` and the REPL `kics2i` | Curry (`src/KiCS2/`), compiled to Haskell by KiCS2 itself | 58 generated modules, 254,000 lines (the compiler's 81,000, the Prelude and libraries' 56,000, the CPM packages' 117,000) | translates FlatCurry into Haskell modules |
| the libraries | Curry (`lib-trunk/src`, the `base` package) | compiled on demand | the Curry Prelude and libraries, each with a `.kics2.hs` file of Haskell primitives |

## Bootstrapping without GHC

The compiler is written in Curry, so a Curry system is needed once to
turn it into Haskell.  The distribution's `kics2c` (a GHC-built arm64
executable) does that and needs no GHC itself: it only writes Haskell.
Done in `ref/kics2-dist/kics2-3.5.0-arm64-darwin`:

```sh
cp -R lib-trunk/src/. lib/                     # what the distribution's make does
cd src && ln -s ../bin bin && ln -s ../lib lib # kics2c finds bin/kics2-frontend relative to the directory it runs in
HOME=$SCRATCH ../bin/.local/kics2c -v1 \
  -i .:../lib:$(ls -d ../.cpm/packages/*/src | tr '\n' ':') KiCS2.Compile
```

`HOME` is redirected because kics2c writes `~/.kics2rc`.  The result is
`.curry/kics2-3.5.0/**/Curry_*.hs` next to each source tree: the 58
modules above, with `boot/CompileBoot.hs` (`main = evalDIO d_C_main`) as
their main module.  The REPL's modules come the same way from
`KiCS2.REPL`.

## What the generated Haskell needs

From the pragmas and a first reading:

- **QuantifiedConstraints** (in every module): a Curry class over a type
  constructor becomes a constraint like `(forall x0 . Curry x0 =>
  Curry (t x0))`.  This is listed as not supported in GHC-EXTENSIONS.md
  (tier 4); KiCS2 makes it a requirement.
- RankNTypes (search strategies take `forall b . NormalForm b => ...`),
  ExistentialQuantification, MultiParamTypeClasses, FlexibleInstances,
  ScopedTypeVariables, PolyKinds, MagicHash and BangPatterns in the
  Prelude (`Int#`, `Char#`, `chr#` from GHC.Exts), CPP keyed on
  `__GLASGOW_HASKELL__`.
- The runtime: `{-# SOURCE #-}` imports between ID and IDSupply (Yale
  compiles the cycle as one unit), `unsafeCoerce`, `unsafePerformIO`,
  `GHC.IO.unsafeDupableInterleaveIO`, IORef, mtl's State, Typeable and
  Control.Exception; tree-monad and parallel-tree-search from Hackage
  (parallel's Control.Parallel; Yale's `par` sparks work on SBCL).
- Size: 254,000 lines of generated code in large modules (the Prelude
  alone is 44,000 lines) tests compile time and the back end more than
  any target so far.
- curry-frontend: Haskell 2010 with DeriveGeneric/DeriveAnyClass,
  TupleSections, LambdaCase, RecursiveDo, MultiWayIf; one Template
  Haskell splice (`embedFile` of a CSS file for HTML output, file-embed);
  Hackage packages extra, set-extra, file-embed, network-uri, binary.

## Testing KiCS2 faithfully: the other Curry tools (2026-10-24)

Today the only reference is the distribution's GHC-built `kics2c`, and
only for the Haskell it writes.  Program results and KiCS2's own tests
need more of the Curry toolchain.  On this machine SWI-Prolog 10.0.2,
Go 1.27.2 and OpenJDK 25 are already installed (Homebrew, `/usr/bin`).

| Tool | What it is | Needs | What it gives us |
|---|---|---|---|
| **CPM** (`cypm`, the Curry Package Manager) | A Curry program: sources in the distribution's `currytools/cpm` | a Curry system to compile it: Yale's kics2c + Yale (as kics2's own `make` does with GHC) | `cypm install curry-check` and the other packages KiCS2's testsuite and tools use; a large real Curry program as a test in itself |
| **curry-check** | A CPM package: runs a module's properties (EasyCheck) and unit tests | CPM, network access to the package index | `testsuite/test.sh` (LanguageTests, TypeclassTests, SpecialTests): KiCS2's own test suite, which skips itself without it |
| **PAKCS** | Curry compiled to Prolog | SWI-Prolog (present) or SICStus | an independent oracle: the same Curry program's values under a different implementation, for the benchmarks and for SearchSMM-like searches |
| **Curry2Go** | Curry compiled to Go, with fair parallel search | Go (present) | a second oracle, and one whose search is breadth-first and fair: it gives values for NDNums and BFSvsPar, which loop under KiCS2's depth-first search |

Order: build CPM with Yale (it doubles as a stress test), then
curry-check, then the testsuite; install PAKCS beside it for comparing
outputs (`run-curry.sh` and `pakcs :eval` on the same goals).  The tools
go in `ref/` or `build/`, untracked, as the distribution does.

## Steps

1. **curry-frontend** with MicroCabal's Yale backend (a local project
   install).  The one TH splice is either run by Yale's TH (file-embed
   needs `runIO` and a ByteString literal) or patched to a string
   constant.  Done when `kics2-frontend` built by Yale writes the same
   FlatCurry as the distribution's for the Prelude and the compiler.
2. **The runtime and its Hackage dependencies** (tree-monad,
   parallel-tree-search) as a package, with the `idsupplyioref` supply.
3. **QuantifiedConstraints**: a given `forall x. C x => D (t x)` is a
   dictionary function in the dictionary-passing translation; a wanted
   `D (t a)` is solved by applying it to the `C a` dictionary.  Small
   tests first, then the generated Prelude.
4. **The generated compiler**: the 58 modules with
   `boot/CompileBoot.hs`, built as an executable.  Done when Yale's
   `kics2c` writes the same Haskell as the distribution's for the
   library and its own sources (a fixed point, as KiCS2's own stage 2
   and 3 bootstrap checks).
5. **Running Curry programs**: `kics2i` calls GHC to build the program it
   generates (`KiCS2.Linker`, the REPL's compile command); make it call
   `yale-haskell` instead (a patch in `tools/conformance/kics2/`), then
   run KiCS2's testsuite (`testsuite/`) and examples against the
   distribution's output.

Steps 1 and 3 are independent and can go first; step 4 needs 2 and 3.
