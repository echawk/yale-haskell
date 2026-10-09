# Plan: real-world Haskell targets

Conformance so far is the Haskell 98 Report, nofib (43 pass) and our
own tests.  The next measure is real code people use.  The difficulty
is less the language than *base*: most code since ~2015 assumes GHC's
modern base (Applicative ⇒ Monad, Semigroup/Monoid, Foldable,
Traversable, MonadFail) and a few extensions.

## The ladder

Each rung is a real codebase, chosen to need one new thing at a time.

1. **`pretty`** (Text.PrettyPrint.HughesPJ): Haskell 98, no
   extensions.  Tests the compiler on idiomatic library code and gives
   us a pretty printer.
2. **QuickCheck 1.x**: Haskell 98 plus `Random`.  Brings property
   testing to our own test suite.
3. **parsec 2.x**: Haskell 98 (parsec 3 needs MultiParamTypeClasses and
   FlexibleInstances).  A real parser library.
4. **A Happy- or Alex-generated parser**: both can emit plain Haskell 98
   (no GHC-specific output); large, generated, table-driven code is a
   good stress test of compile time and the GRIN back end.
5. **MicroCabal** (MICROCABAL.md): Haskell 2010 by design; needs the
   Applicative layer and one multi-parameter class.
6. **The modern-base Prelude** (MICROCABAL.md step 2b) — after it,
   `containers`-style code, `mtl`-style monad transformers (need
   MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances),
   and parsec 3 become reachable.
7. **CPP**: a `{-# LANGUAGE CPP #-}` pass (a small C-preprocessor
   subset in Lisp: `#if`, `#ifdef`, `#define` of simple macros,
   `MIN_VERSION_x(a,b,c)`), needed by most Hackage packages.

## How to run a rung

- Clone into `ref/` (gitignored).  Record any workaround as a patch in
  `tools/<target>/`, never as edits to the clone.
- A survey script that loads each module in dependency order and
  prints the first error (as tools/microcabal/survey.sh does).
- Done when the package's own tests or examples run with output
  matching GHC; then add a small representative program to
  `tests/haskell98/` so the rung stays climbed.

## Extensions likely to be needed, roughly in order of payoff

MultiParamTypeClasses + FunctionalDependencies; FlexibleInstances /
FlexibleContexts; ScopedTypeVariables (explicit `forall`, scoped type
variables in local signatures); TupleSections; LambdaCase;
BangPatterns; GeneralizedNewtypeDeriving; RankNTypes (needed by `ST`
and lens-like code, hardest); GADTs and TypeFamilies (out of scope for
now).  The `LANGUAGE` pragma is ignored today; it should become a
switch per extension once the first one exists.
