# Plans

Longer-range work, one plan per topic, written 2026-10-09 from the
`todo` file.  Each plan says what is known, the steps, and how to tell a
step is done.  REVIVAL-PLAN.md remains the milestone history (M1–M11);
these are what comes after M11.

| Plan | Topic | Status |
|---|---|---|
| [CONFORMANCE.md](CONFORMANCE.md) | Haskell 98 / Haskell 2010 conformance: the export checker, nofib, what remains | in progress |
| [MICROCABAL.md](MICROCABAL.md) | Build MicroCabal (a Haskell 2010 Cabal subset) with Yale Haskell, then use it to build packages | in progress |
| [REAL-WORLD-TARGETS.md](REAL-WORLD-TARGETS.md) | A ladder of real Haskell code to compile, below and beyond MicroCabal | planned |
| [LISP-INTEROP.md](LISP-INTEROP.md) | Calling Haskell from Common Lisp; Haskell as a reader macro | planned |
| [PORTABILITY.md](PORTABILITY.md) | Running on Lisps other than SBCL (ECL, ABCL, CCL) | ECL 193/200, ABCL 162/200 |
| [SPECIALIZE.md](SPECIALIZE.md) | Copies of recursive overloaded functions for known dictionaries (GHC's SPECIALISE), as a step of the optimizer | planned |
| [MUMBLE-TO-CL.md](MUMBLE-TO-CL.md) | Moving the compiler from mumble to plain Common Lisp, piece by piece | planned |

Suggested order: MicroCabal (it doubles as the gap list for real
code), then Lisp interop, with the mumble → CL move and portability
done alongside, a directory or a file at a time.
