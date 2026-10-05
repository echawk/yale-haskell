# Haskell 98 libraries (work in progress)

This tree is the Haskell 98 counterpart of `lib/haskell-1.2/`.  It is
built as a separate *dialect*: `make` compiles both Preludes and saves
one executable per dialect, and `bin/yale-haskell --haskell98` selects
this one.

| Path | Contents |
|---|---|
| `prelude/` | the Prelude.  It started as a copy of the 1.2 Prelude and is being moved towards the H98 Report's Standard Prelude as the compiler gains the language features it needs. |
| `*.hs` (to come) | the H98 standard libraries: `List`, `Char`, `Maybe`, `Numeric`, `Ratio`, `Complex`, `Ix`, `Array`, `Monad`, `IO`, `System`, `Directory`, `Time`, `Locale`, `CPUTime`, `Random` |

Reference material: the Report (`ref/haskell-report`, branch `h98`) is
the specification; Hugs (`ref/hugs98`, `libraries/hugsbase/Hugs/Prelude.hs`
and `packages/haskell98`) is the reference implementation.  See
`ref/README.md` for licensing when borrowing code.

The compiler still implements Haskell 1.2 (no constructor classes,
`do`, `newtype`, records or qualified names; see
`doc/REVIVAL-PLAN.md` §3).  Anything here must compile with the
compiler as it is today; definitions that need a missing feature are
left out until that feature lands, and the tests that need them are
marked as expected failures (`tests/README.md`).
