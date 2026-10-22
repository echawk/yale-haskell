# Plans

Longer-range work, one plan per topic, written 2026-10-09 from the
`todo` file.  Each plan says what is known, the steps, and how to tell a
step is done.  REVIVAL-PLAN.md remains the milestone history (M1–M11);
these are what comes after M11.

| Plan | Topic | Status |
|---|---|---|
| [CONFORMANCE.md](CONFORMANCE.md) | Haskell 98 / Haskell 2010 conformance: the export checker, nofib, what remains | in progress |
| [MICROCABAL.md](MICROCABAL.md) | Build MicroCabal (a Haskell 2010 Cabal subset) with Yale Haskell, then use it to build packages | mcabal runs with a Yale backend; about 80 Hackage packages build (Agda's dependencies) |
| [REAL-WORLD-TARGETS.md](REAL-WORLD-TARGETS.md) | A ladder of real Haskell code to compile, below and beyond MicroCabal: darcs, husk-scheme, happy, optparse-applicative, and now Agda | ladder climbed; Agda in progress (2026-10-22) |
| [LISP-INTEROP.md](LISP-INTEROP.md) | Calling Haskell from Common Lisp; Haskell as a reader macro | planned |
| [PORTABILITY.md](PORTABILITY.md) | Running on Lisps other than SBCL (ECL, ABCL, CCL) | ECL 193/200, ABCL 162/200 |
| [GHC-OPTIMIZATIONS.md](GHC-OPTIMIZATIONS.md) | Every GHC optimisation pass, what Yale has for it, and where the missing ones go in Yale's pipeline | reference and plan |
| [SPECIALIZE.md](SPECIALIZE.md) | Copies of recursive overloaded functions for known dictionaries (GHC's SPECIALISE), as a step of the optimizer | done (2026-10-11) |
| [GHC-EXTENSIONS.md](GHC-EXTENSIONS.md) | GHC extensions and modern libraries: what is supported exactly, permissively or by approximation, what is realistic, what is not | 101/104 probes; updated for Agda (2026-10-22) |
| [CUBICALTT.md](CUBICALTT.md) | cubicaltt, a cubical type theory proof checker, as the program that tests the GHC features together; what it needed, its speed against GHC, and the library and optimization targets that follow | cubicaltt 42/42, LambdaPi and Mini-TT match GHC |
| [MUMBLE-TO-CL.md](MUMBLE-TO-CL.md) | Moving the compiler from mumble to plain Common Lisp, piece by piece | planned |
| [TEMPLATE-HASKELL.md](TEMPLATE-HASKELL.md) | Template Haskell and QuasiQuotes: the design (from the TH papers and GHC's guide), where it goes in Yale's pipeline, files to change, pain points, milestones | milestones 1-4 done (2026-10-18); QuasiQuotes, typed TH to do |
| [LIQUID-HASKELL.md](LIQUID-HASKELL.md) | Refinement types in LiquidHaskell's style: a typed core after cfn, `{-@ @-}` specifications, constraint generation, Z3 and a fixpoint solver, milestones and pain points | milestone 1, the typed core, done (2026-10-17); rest design |
| [FUTURE-TARGETS.md](FUTURE-TARGETS.md) | Further real-world targets to try compiling (inline-java, JHC, rusholme, Helium, UHC, NHC98, KiCS2) | proposed (2026-10-14; order after Agda 2026-10-22) |

Current order (2026-10-22): Agda through MicroCabal until its own test
suite passes; then stress tests on FFI-heavy and modern-GHC libraries;
then KiCS2 (REAL-WORLD-TARGETS.md, "After Agda").  Lisp interop, the
mumble → CL move and portability continue alongside, a directory or a
file at a time.
