# Building Haskell projects and Hackage packages with Yale Haskell

Yale Haskell compiles Haskell source to native code through SBCL.  It
has no GHC-style package manager of its own; instead the repository
carries a backend for [MicroCabal](https://github.com/augustss/MicroCabal)
(`tools/microcabal/`) that lets `mcabal` read a `.cabal` file, fetch the
dependencies from Hackage, and build them and your project with
`bin/yale-haskell`.

This guide covers running a single file, making a standalone
executable, and building a cabal project with Hackage dependencies.
Everything here was run against version 3.0.15.0 on macOS/arm64 (the
package list under "What works today" against 3.1.0.0 and later); the
design notes and survey tables are in
[plans/MICROCABAL.md](plans/MICROCABAL.md).

Package support is partial.  Read "What works today" before choosing a
dependency.

## Prerequisites

1. Build Yale Haskell (see the top-level README.md): SBCL, `make`,
   ocicl.

   ```sh
   make deps && make
   ```

   This produces `bin/yale-haskell`.
2. For `mcabal`: `curl`, `tar`, `patch`, and a network connection (the
   Stackage package list and the package tarballs are fetched).  The
   first run of `tools/microcabal/mcabal` builds MicroCabal itself, by
   running `tools/microcabal/setup.sh`, which copies the MicroCabal
   sources from `ref/MicroCabal` into `build/microcabal/src` and adds
   the Yale backend.  `setup.sh` stops with "no ref/MicroCabal" if that
   clone is missing:

   ```sh
   git clone --depth 1 https://github.com/augustss/MicroCabal ref/MicroCabal
   ```

   (The survey in doc/plans/MICROCABAL.md used version 0.5.10.0.)  The
   copy is rebuilt automatically when `Yale.hs`, `yale-backend.patch`,
   `mcabal.hs` or the clone changes.

## Running one file

```sh
bin/yale-haskell --haskell98 prog.hs a b     # runs Main.main; a b are getArgs
```

Given this `hello.hs`:

```haskell
module Main (main) where
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  putStrLn ("Hello from Yale Haskell, args = " ++ show args)
  print (sum [1 .. 100 :: Int])
```

```
$ bin/yale-haskell --haskell98 hello.hs a b
Hello from Yale Haskell, args = ["a","b"]
5050
```

The first run compiles the program and the libraries it uses; the
compiled units are cached (see "Troubleshooting"), so later runs are
fast.

### Language modes

With no language flag the compiler reads **Haskell 1.2**, the language
of the original Yale Haskell (`main` is a `Dialogue`; the example
programs in `examples/` are written that way).  A modern program needs
one of these:

| Flag | Language | Prelude |
|---|---|---|
| `--haskell98` | Haskell 98 | the Haskell 98 Prelude |
| `--haskell2010` | Haskell 2010 | the Haskell 2010 Prelude |
| `--modern-prelude` | as above, plus the names of GHC base's Prelude (Applicative, MonadFail, Semigroup/Monoid, Foldable/Traversable, `Word`) | GHC base's |
| `--ghc2021` | GHC2021: its extensions on in every module; implies `--modern-prelude` | GHC base's |
| `--ghc2024` | GHC2024: GHC2021 plus DataKinds, GADTs, LambdaCase, ...; implies `--modern-prelude` | GHC base's |
| `-X NAME`, `-XNAME` | turn one more extension on for every module; `-X NoNAME` turns one off | unchanged |

Notes from testing:

- Each flag is a separate argument: `--haskell98 --modern-prelude`,
  not `"--haskell98 --modern-prelude"`.  `mcabal` itself runs everything
  with `--haskell98 --modern-prelude`.
- A `{-# LANGUAGE ... #-}` pragma in a file works as in GHC (a program
  using `\case` ran under `--haskell98` with the pragma, `--ghc2021`,
  and `-X LambdaCase`).  A `{-# LANGUAGE GHC2021 #-}` pragma, or a
  package's `default-language`, switches one module to that language.
- `CPP` files go through a built-in C preprocessor; `--cpp`, `-D` and
  `-I` are as for cpp.  `__GLASGOW_HASKELL__` is deliberately not
  defined, so that libraries pick their portable code.
- `bin/yale-haskell --help` lists everything.  The interactive system
  is described in [REPL.md](REPL.md).

### Finding modules

Imports are looked for next to the importing file, then in `-i DIR`
directories (and `$YALE_HASKELL_PATH`, colon-separated), then in
installed packages (`--package-db DIR`, or `$YALE_HASKELL_PACKAGE_DB`).
A package directory is `NAME-VERSION/` with `src/`, optional
`include/`, and a `yale-package` file; `mcabal` writes these.  So,
after installing `split` (below), a plain file can use it:

```
$ cat t.hs
import Data.List.Split (chunksOf)
main :: IO ()
main = print (chunksOf 3 [1 .. 10 :: Int])
$ bin/yale-haskell --ghc2021 --package-db $CABALDIR/yale-3.0.15.0/packages t.hs
[[1,2,3],[4,5,6],[7,8,9],[10]]
```

A module that cannot be found gives, for example:

```
[UNDEFINED-MODULE-IMPORT] Fatal error in phase IMPORT:
Cannot find module Data.Foo, imported by module Main.
```

## A standalone executable

```sh
bin/yale-haskell --haskell98 build hello.hs -o hello
./hello x --help
```

```
Hello from Yale Haskell, args = ["x","--help"]
5050
```

`build` writes an executable that contains the whole Lisp image with the
program compiled in (about 65 MB for `hello`).  Every command-line
argument belongs to the program, `--help` included, and the executable
needs neither the source tree nor any environment.  Without `-o` it is
named after the file.  The same language and `--package-db` flags apply.

## A cabal project with Hackage dependencies

### Where things go

`mcabal` keeps everything in `$CABALDIR`.  **If it is not set, it is
`$HOME/.mcabal`.**  `tools/microcabal/hackage-survey.sh` uses
`build/mcabal` in the checkout instead; to keep the project's packages
out of your home directory, set it yourself:

```sh
export CABALDIR=$PWD/.mcabal        # or any directory
```

| Path | Contents |
|---|---|
| `$CABALDIR/packages.txt`, `snapshot.yaml`, ... | the Stackage package list (`mcabal update`) |
| `$CABALDIR/packages/NAME-VER/` and `.tar.gz` | downloaded sources |
| `$CABALDIR/yale-VERSION/packages/NAME-VER/` | installed packages, as sources (`src/`, `include/`, `yale-package`); VERSION is Yale Haskell's version |
| `$CABALDIR/bin/` | installed executables |
| `dist-mcabal/` in the project | build directory; `dist-mcabal/bin/yale/NAME` is the executable `build` makes |

Packages are installed as sources because Yale Haskell compiles from
source and caches the compiled units; installing compiles the package
once so that later builds are fast.  A new Yale Haskell version uses a
new `yale-VERSION` directory, so packages are installed again.

### Steps

Take this project: `wordsplit.cabal`

```cabal
cabal-version:      2.2
name:               wordsplit
version:            0.1.0.0
build-type:         Simple

executable wordsplit
  main-is:          Main.hs
  hs-source-dirs:   app
  build-depends:    base, split, safe
  default-language: Haskell2010
```

and `app/Main.hs`:

```haskell
module Main (main) where

import Data.List.Split (splitOn)
import Safe (headMay, readMay)
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let line = case args of
               (a:_) -> a
               []    -> "1,2,x,4"
      fields = splitOn "," line
  putStrLn ("fields: " ++ show fields)
  putStrLn ("first:  " ++ show (headMay fields))
  print [readMay f :: Maybe Int | f <- fields]
```

Run these in the project directory (`mcabal` is
`tools/microcabal/mcabal` in the Yale Haskell checkout; put it on your
`PATH` or give its path):

```sh
mcabal update            # once: fetch the Stackage package list
mcabal -r install        # build and install the project and, with -r, its missing dependencies
```

Output (real run, with a fresh `$CABALDIR`, about 6 seconds once the
library units were cached):

```
mcabal: Building executable wordsplit
mcabal:   Build package split
mcabal:   Running 'fetch split'
mcabal:   Building library split
mcabal:   Building library split with yale
mcabal:   Installing library split
mcabal: Return to building target
mcabal:   Build package safe
mcabal:   Running 'fetch safe'
mcabal:   Building library safe
mcabal:   Building library safe with yale
mcabal:   Installing library safe
mcabal: Return to building target
mcabal: Building executable dist-mcabal/bin/yale/wordsplit with yale
mcabal: Installing executable wordsplit
```

```
$ $CABALDIR/bin/wordsplit
fields: ["1","2","x","4"]
first:  Just "1"
[Just 1,Just 2,Nothing,Just 4]
$ $CABALDIR/bin/wordsplit a,b,3
fields: ["a","b","3"]
first:  Just "a"
[Nothing,Nothing,Just 3]
```

(`mcabal update` is not strictly needed if `$CABALDIR` already has the
list; `hackage-survey.sh` runs it when `packages.txt` is missing.  In
the run above, the first `-r install` found the list from an earlier
`update`.)

Other commands (`mcabal help`):

- `mcabal build` builds the project in the current directory without
  installing: `dist-mcabal/bin/yale/wordsplit` is the executable.
  Without `-r`, a dependency that is not installed stops it:
  `dependency not installed: split` (preceded by "Haskell runtime
  abort.").
- `mcabal [-r] install PKG` installs a package from Hackage (and, with
  `-r`, its dependencies).  `mcabal install` in a directory installs
  that project.
- `mcabal fetch PKG`, `mcabal clean`, `mcabal parse FILE.cabal`,
  `mcabal test`.
- `-fFLAG` sets a cabal flag, `-v` is more verbose, `-q` quiet,
  `--dry-run` prints the commands without running them,
  `--options=OPTIONS` passes options to the compiler, `--git=URL` takes
  a package from a Git repository.  `--ghc` and `--mhs` select the other
  backends of MicroCabal; `--yale` is the default.

### What the backend does

- A library is built by compiling one module that imports every exposed
  and other module, then installed by copying its sources into
  `$CABALDIR/yale-VERSION/packages` and compiling again there.
- An executable is built with `yale-haskell build`, so it is a
  standalone executable (80 MB or so), and `install` copies it to
  `$CABALDIR/bin`.
- Each package's `default-language`, `default-extensions`, `cpp-options`
  and `include-dirs` are recorded in its `yale-package` file and apply
  to its own modules only.  The compiler runs with `--haskell98
  --modern-prelude` plus those.
- The packages Yale Haskell provides itself count as installed and are
  never fetched: base, ghc-prim, array, containers, bytestring, text,
  deepseq, directory, filepath, process, time, mtl, transformers,
  parsec, pretty, random, stm, parallel, binary, QuickCheck, hashable,
  unordered-containers, scientific, haskeline, ansi-terminal,
  utf8-string, old-time, old-locale, xhtml, unix, knob, ghc-boot-th
  (GHC.Lexeme), ghc-compact, and the
  compatibility packages fail, semigroups, void, nats, tagged-compat
  (the list is `builtinPackages` in `tools/microcabal/Yale.hs`).  They
  are "complete, or in the part commonly used", so a program may still
  find a module or function missing.
  `template-haskell` also counts as installed, so that packages depend on
  it; Template Haskell itself is only partly there (below).
- `impl(ghc ...)` conditions in a `.cabal` file are false (the compiler
  is called `yale`).
- A `.hsc` module is preprocessed by `tools/microcabal/yale-hsc2hs`
  (`$YALE_HSC2HS`), which handles hsc2hs's constructs (`#{const ..}`,
  `#peek`, `#poke`, `#size`, ...) by compiling the file into a C program
  that prints the module, as hsc2hs does; one with only CPP is read
  directly.

### Environment variables

| Variable | Meaning |
|---|---|
| `CABALDIR` | installation directory (default `$HOME/.mcabal`) |
| `YALE` | the `yale-haskell` the backend runs (default: this checkout's `bin/yale-haskell`) |
| `YALE_CPP_OPTIONS` | extra cpp options (words, e.g. `-D__GLASGOW_HASKELL__=906`) added to every package the backend stages, for packages that insist on GHC; alex needs it (`doc/plans/MICROCABAL.md`) |
| `YALE_MCABAL_PATCHES` | directory of per-package patches (default `tools/microcabal/patches`, set by the `mcabal` script) |
| `YALE_HASKELL_PACKAGE_DB`, `YALE_HASKELL_PATH` | for `bin/yale-haskell` itself, see above |
| `YALE_HASKELL_CACHE_DIR`, `YALE_HASKELL_CACHE` | the compiled-unit cache (below) |

Defining `__GLASGOW_HASKELL__` makes packages choose their GHC-specific
code, which usually needs `GHC.*` internals Yale Haskell lacks, so use
it only for a package that stops at `#error This code isn't being built
with GHC` (alex, dlist).

### Per-package patches

Some packages contain code that only GHC was meant to compile.  Each
`NAME.patch` in `tools/microcabal/patches/` is applied (`patch -p1`,
paths relative to the package's `src/` tree) when the backend stages the
package named `NAME`; "Patching NAME with ..." is printed.  A
`NAME.cpp-options` file there adds cpp options (`-D...`) for that
package only.  About twenty packages have one or the other today
(aeson, async, ListLike, monad-control, primitive, regex-tdfa, tagged,
...): each replaces a GHC-only construct with portable code and says
why.  To add one, drop a file of that name there, or set
`YALE_MCABAL_PATCHES` to your own directory.  A patch applies to every
version of the package.

## What works today

Of the 43 popular libraries in `tools/microcabal/hackage-survey.sh`, the
survey recorded in doc/plans/MICROCABAL.md reached 11 building after
3.0.8.0, and the changelog adds comonad, indexed-traversable and
others since.  The following were built (installed) by the survey in this
checkout, and `split`, `safe` and `optparse-applicative` were built again
from a fresh `$CABALDIR` while writing this guide:

split, safe, base-orphans, splitmix, assoc, call-stack, HUnit,
utility-ht, parser-combinators, prettyprinter,
prettyprinter-ansi-terminal, optparse-applicative, tagged, StateVar,
colour, case-insensitive, data-default, distributive, comonad,
indexed-traversable.

Executables: alex 3.5.4.2 builds (`YALE_CPP_OPTIONS=-D__GLASGOW_HASKELL__=906
mcabal -r install alex`) and generates the same scanners as the
GHC-built one on its test grammars.

Since 3.1.0.0 the work toward Agda (doc/plans/MICROCABAL.md, "Agda's
dependency chain") has installed about 80 packages in `build/mcabal`,
among them aeson, async, vector, primitive, profunctors, semigroupoids,
bifunctors, comonad, generic-data, generic-deriving, ListLike,
regex-tdfa, zlib, pqueue, nonempty-containers, monad-control,
th-abstraction, happy (its libraries) and alex.

To check a package yourself:

```sh
tools/microcabal/hackage-survey.sh -t 600 PKG ...   # "ok"/"FAIL" plus the first error; logs in $CABALDIR/survey/
```

(without arguments it tries the whole list, into `build/mcabal` unless
`$CABALDIR` is set).  The tables in doc/plans/MICROCABAL.md are
dated: a package listed there as failing may build now.

### Limitations

- **Template Haskell is partly supported**: the library
  (`Language.Haskell.TH`), name quotes, quotes, expression and
  declaration splices of imported functions, and `reify` of types and
  constructors, but not yet QuasiQuotes, `reify` of classes, or typed TH
  (doc/plans/TEMPLATE-HASKELL.md).  So `mcabal` still
  installs a module with `{-# LANGUAGE TemplateHaskell #-}` or
  `QuasiQuotes` without compiling it; a package exposing such a module
  next to others (tagged's Data.Proxy.TH) still builds, but anything that
  imports it fails.  Packages that need TH at their core (aeson via
  exceptions, lens, ...) do not build.
- `GHC.*` internals are approximated: unboxed types are boxed, GHC.Exts'
  primops (arrays, byte arrays, Addr#, MutVar#, MVar#) are ordinary
  operations threaded by the State# token, so primitive and vector
  build; a package relying on exact unboxed representations or GHC's
  runtime (weak pointers' timing, the RTS) may not.
- A package's C code (`c-sources`, `cxx-sources`, `extra-libraries`,
  `frameworks`, `pkgconfig-depends`, a `configure` script) is compiled
  and linked into `lib/libHSNAME.so`, loaded with the package
  (doc/FFI.md); the C compiler (`cc`, `c++`) and `pkg-config` come from
  the system.  Boot packages Stackage does not list (integer-gmp) are
  not fetched; `foreign-library` stanzas (a Haskell library built as a
  C shared library) raise "foreign-library is not supported".
- Mutually recursive modules are compiled as one unit when their files
  import each other; `hs-boot` files are ignored.
- `Int` is a 63-bit fixnum, not 64-bit (the only deliberate departure
  noted in doc/plans/GHC-EXTENSIONS.md; programs that rely on Int
  wrap-around differ).
- Executables are 65-90 MB each: they contain the Lisp image.

## Troubleshooting

| Message | Meaning |
|---|---|
| `Invalid syntax appears where a topdecl is expected` on a program that is valid Haskell 98 | no language flag was given, so the file was read as Haskell 1.2.  Add `--haskell98` or `--ghc2021` |
| `Cannot find module M, imported by module Main` | the module is not next to the file, not in `-i` or `$YALE_HASKELL_PATH`, and not in a `--package-db`.  Install the package, and pass `--package-db $CABALDIR/yale-VERSION/packages` (or set `YALE_HASKELL_PACKAGE_DB`) when running a single file |
| `dependency not installed: PKG` (after `Haskell runtime abort.`) | `build`/`install` without `-r`; install the dependency, or add `-r` |
| `setup.sh: no ref/MicroCabal` | clone MicroCabal into `ref/` (see Prerequisites) |
| a failure inside a package's module, e.g. a parse error or missing name | a limitation in the list above, or a Yale Haskell bug.  Run `hackage-survey.sh PKG` to see the first error; check doc/plans/MICROCABAL.md; a package-specific GHC-ism may need a patch or `YALE_CPP_OPTIONS` |
| `#error This code isn't being built with GHC` | set `YALE_CPP_OPTIONS=-D__GLASGOW_HASKELL__=906` for that install |
| `stack overflow`, exit status 2 | the program ran out of its 512 MB control stack; `YALE_HASKELL_STACK_MB` sets another size |
| a crash with no Haskell message when the heap runs out | `YALE_HASKELL_DEBUG=1` prints a backtrace |
| a compile that seems to hang (no output: a package's units print nothing) | `YALE_HASKELL_TRACE=1` prints each unit and phase as it starts, and each phase's time, on standard error; `YALE_HASKELL_BACKTRACE_AFTER=N` prints the threads' backtraces after N seconds |
| mcabal rejects a `.cabal` file (for example an empty `Default-Extensions:` field, or `{ }` blocks after `if`) | MicroCabal's own parser (GHC-built MicroCabal rejects them too); edit the cabal file |

### Cache

Compiled modules are cached in `~/.cache/yale-haskell/` (or
`$YALE_HASKELL_CACHE_DIR`), keyed by the sources and the compiler
version; a program compiles once and later runs reuse it.
`YALE_HASKELL_CACHE=0` turns it off, `YALE_HASKELL_CACHE=library` limits
it to library modules.  A new build of Yale Haskell starts a new cache
and removes those of the same checkout's older builds.  To clear it,
delete that directory.  After a source change that the cache does not
notice, delete the cache directory (and, for a package, its directory in
`$CABALDIR/yale-VERSION/packages`) and install again.
