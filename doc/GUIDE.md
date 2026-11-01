# Using Yale Haskell

A guide for Haskell programmers who want to use Yale Haskell in place of
GHC and cabal, and for Common Lisp programmers who want Haskell in their
Lisp.  The details are in the documents it points to; README.md says
what Yale Haskell is and how it performs.

## Building it

You need [SBCL](https://www.sbcl.org) 2.6 or later, `make`, and
[ocicl](https://github.com/ocicl/ocicl) (the Lisp libraries are pinned
in `ocicl.csv`).  For Hackage packages, also `curl`, `tar` and `patch`.
GHC is not needed.

```sh
git clone <this repository> yale-haskell && cd yale-haskell
make deps        # ocicl install: the Lisp libraries, into ocicl/
make             # the compiler, the Haskell 98 library, bin/yale-haskell
```

A build takes a few minutes and puts everything under `build/`.  Put
`bin/` on your `PATH`, or call `bin/yale-haskell` by its path.  The
executable finds its library through the checkout, so keep the tree
where it was built (or rebuild after moving it).

## The GHC workflow, translated

| GHC / cabal | Yale Haskell |
|---|---|
| `runghc Main.hs a b` | `yale-haskell Main.hs a b` |
| `ghc Main.hs -o prog` | `yale-haskell build Main.hs -o prog` |
| `ghci Main.hs` | `yale-haskell repl Main.hs` (doc/REPL.md) |
| `ghc -e 'expr'` | `yale-haskell -e 'expr'` |
| `-XLambdaCase`, `{-# LANGUAGE ... #-}` | the same (`-X NAME` or `-XNAME`) |
| `-i src` | `-i src` |
| `-cpp -DFOO` | `--cpp -D FOO` (and `{-# LANGUAGE CPP #-}`) |
| `-ddump-simpl`, `-ddump-asm` | `yale-haskell compile Main.hs --emit flic,lisp,asm` |
| `+RTS -N4` | `+RTS -N4` (`par` sparks run on 4 threads) |
| `+RTS -s` | `YALE_HASKELL_TIME=1` (time, GC and bytes allocated of `main`) |
| `-prof`, `+RTS -p` | `YALE_HASKELL_PROFILE=1` (SBCL's statistical profiler) |
| `cabal update` | `mcabal update` |
| `cabal install pkg` | `mcabal -r install pkg` |
| `cabal build`, `cabal run` | `mcabal -r build`, then `dist-mcabal/bin/yale/NAME` |
| `cabal install` (a project's executable) | `mcabal -r install`, then `$CABALDIR/bin/NAME` |
| `cabal repl` | `yale-haskell --ghc2021 --package-db $CABALDIR/yale-VERSION/packages repl app/Main.hs` |

`mcabal` is `tools/microcabal/mcabal`: MicroCabal (Lennart Augustsson's
small Cabal) with a Yale Haskell backend, run by Yale Haskell itself.

There is no separate compile step to remember: `yale-haskell Main.hs`
compiles what changed and runs it.  Compiled modules are cached in
`~/.cache/yale-haskell/`, so the second run of a program starts in a
fraction of a second.

## Languages

With no flag a program is Haskell 98, as most textbook and old code is.
For modern code:

| flag | language | Prelude |
|---|---|---|
| (none) | Haskell 98 | Haskell 98's |
| `--haskell2010` | Haskell 2010 | Haskell 2010's |
| `--modern-prelude` | the language above, with GHC base's Prelude (Applicative, Foldable, Semigroup, `<$>` ...) | base's |
| `--ghc2021`, `--ghc2024` | GHC's languages of those names, every extension in them on | base's |

Code written for GHC usually wants `--ghc2021`.  A file's `LANGUAGE`
pragmas work as with GHC, and a package's `default-language` and
`default-extensions` apply to its modules.  `--haskell1.2` is the
original 1990s system (`make haskell-1.2` builds it).

The library has base's modules under their GHC names, and containers,
text, bytestring, mtl, transformers, stm, deepseq, parsec, filepath,
directory, process, time, random, array and QuickCheck (most of it):
code that uses only those needs no packages.

## Hackage packages

```sh
export CABALDIR=$HOME/.mcabal          # the default; any directory will do
tools/microcabal/mcabal update         # once: Stackage's package list
tools/microcabal/mcabal -r install split
```

Installed packages are kept as source in
`$CABALDIR/yale-VERSION/packages/` and compiled the first time a
program imports them (then cached).  A single file uses them with
`--package-db`:

```sh
yale-haskell --ghc2021 --package-db $CABALDIR/yale-3.1.0.0/packages t.hs
```

(`$YALE_HASKELL_PACKAGE_DB` does the same.)  A project with a `.cabal`
file is built in its directory with `mcabal -r build` or installed with
`mcabal -r install`; `-r` installs missing dependencies first.
doc/PACKAGES.md walks through a project, lists about 80 packages known
to build (aeson, vector, optparse-applicative, megaparsec,
prettyprinter, ...) and how to patch one that does not.  Versions come
from Stackage's snapshot, not from a solver: a project gets the
snapshot's version of each dependency.

## Things that differ from GHC

- `Int` is SBCL's fixnum: 63 bits, wrapping modulo 2^63, not 2^64.
- There are no unboxed types: `Int#` is `Int`, `(# a, b #)` a tuple,
  and code written with GHC's primops runs at ordinary speed.
- Template Haskell is partial (quotes, splices of imported functions,
  reify of types; not quasi-quotes or reify of classes).
  doc/plans/GHC-EXTENSIONS.md has the full list.
- Of `+RTS` options only `-N` means something; there is no GHC
  profiling, event log or `GHC.Stats`.
- An executable from `build` is the whole Lisp image with the program
  in it: about 65 MB, starting in about 0.05 s.
- Compiling is slower than GHC's: a first compile of aeson and its
  dependencies takes about three minutes.  The unit cache makes it a
  one-time cost per build of Yale Haskell.
- Errors are reported by phase (`[TYPE-ERROR] Phase error in phase
  TYPE`) with the file and line, in a different style from GHC's.

## When something goes wrong

| symptom | what to do |
|---|---|
| `Cannot find module M` | add `-i DIR`, or `--package-db` for an installed package; `mcabal -r install PKG` if it is not installed |
| `The name <$> is undefined` (or `traverse`, `Semigroup`, ...) | the program expects base's Prelude: `--modern-prelude` or `--ghc2021` |
| a program is slow only the first time | it is being compiled; later runs use the cache |
| `stack overflow` (status 2) | deep recursion: `YALE_HASKELL_STACK_MB=2048` gives the program more stack |
| a compile seems stuck | `YALE_HASKELL_TRACE=1` prints each unit and phase with its time |
| a Lisp error or a crash | `YALE_HASKELL_DEBUG=1` prints a Lisp backtrace |

## For Common Lisp programmers

Yale Haskell is a Lisp program: the compiler is written in mumble, a
Scheme-like dialect hosted on Common Lisp (src/mumble/README.md), and
Haskell is compiled to Common Lisp, which SBCL compiles to native code.
`yale-haskell compile F.hs --emit lisp` shows the Lisp.

- **Haskell in Lisp files.**  `#@hs{ ... }#` blocks in a Lisp file are
  compiled in the image, with Lisp values spliced in and Haskell values
  converted back (doc/EMBEDDING.md):

  ```lisp
  (defun fib-of (n) #@hs{ fib ($n :: Int) }#)
  ```

- **Loading Yale Haskell with ASDF.**  `(asdf:load-system
  :yale-haskell/runtime)` loads the compiler and library into your
  image (doc/EMBEDDING.md has the source-registry form);
  `yale-haskell:run-file`, `load-file` and `repl` are there too
  (tools/asdf/api.lisp).
- **Lisp from Haskell.**  A Haskell function can be any Lisp function,
  declared in an interface file with `LispName` (how the Prelude's
  primitives are written: lib/haskell98/*.hi), and C functions through
  the FFI (doc/FFI.md).
- **cl-sml.**  `#@hs{ }#` keeps an earlier `#@` reader, so cl-sml's
  `#@sml{ }#` blocks and Haskell blocks can share a file.
