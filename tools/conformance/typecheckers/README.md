# Small dependently typed checkers: LambdaPi and Mini-TT

Used by `tools/conformance/typecheckers.py` (doc/plans/CUBICALTT.md, "Two
more checkers").  The programs themselves are not kept here (neither
says what licence it is under); the script fetches them at pinned
versions into `ref/`:

- LambdaPi (Löh, McBride and Swierstra, "A tutorial implementation of a
  dependently typed lambda calculus", 2010):
  https://www.andres-loeh.de/LambdaPi/LambdaPi.hs and prelude.lp, checked
  by SHA-256.  Plain Haskell 98 with parsec, old mtl's
  Control.Monad.Error, readline and the Prelude's catch.
- Mini-TT (Coquand, Kinoshita, Nordström and Takeyama, "A simple
  type-theoretic language: Mini-TT", 2009): the paper's Haskell, as
  mirrored at https://github.com/kino3/Mini-TT (442b08f), with
  examples/paper.mtt from https://github.com/scott-fleischman/mini-tt
  (64b615a).  Its parser is generated from Core.cf with BNFC, Alex and
  Happy at run time.

Here: `lambdapi/Main.hs` (a wrapper, as LambdaPi's module is LP),
`lambdapi/*.in` (interpreter sessions), `minitt/bench.mtt`, and
`expected/` (GHC 9.14's output for each, and GHC's time with -O).
