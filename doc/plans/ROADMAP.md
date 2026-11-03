# Roadmap: GHC conformance, correctness and speed (2026-11-02)

An assessment of where Yale Haskell stands against GHC and what to solve
next, in the order agreed on 2026-11-02.  Update the status column as
items are done.

## Where we are

- nofib: 69 imaginary/spectral and 40 real/gc/shootout programs pass.
- Extension probes (`tools/conformance/extensions.py`): 139 of 140; only
  GHCIntWraps fails (Int is the 63-bit fixnum).  README.md still says
  101/104.
- Real programs: cubicaltt, husk-scheme, happy, alex, darcs 1.0.9,
  xmonad's QuickCheck properties, LambdaPi and Mini-TT, optparse's test
  suite, and Agda (builds and checks files; its Succeed suite passed
  1183 of 1852 on 2026-10-27).
- Hackage: about 160 packages have built (build/mcabal and the survey
  databases).  QuickCheck 2.17.1.0, hspec-core and hspec build from
  Hackage and run (2026-11-02).
- Speed: 1.4x GHC -O2's CPU time at the geometric mean (0.1x to 3x) on
  bench/compare-ghc.
- Not yet tried: GHC's own testsuite (its `should_run` tests, thousands
  of small programs with expected output, the best GHC-conformance
  measure), and a batch of ordinary user programs (Advent of Code,
  Rosetta Code, textbook code).

## Pandoc (not yet tried)

pandoc 3.11's dependency closure (Stackage versions, libraries'
build-depends, conditionals included, so an over-estimate): about 190
packages.  75 have already built, 31 are the library's, 84 are new.

- The gate: `http-client-tls` pulls in `tls` and about 15 `crypton-*`
  packages.  crypton needs basement/memory, which fail (basement's
  `Integral Word128` taken for the Prelude's class).
- Other likely trouble: Template Haskell (file-embed, th-lift), C
  libraries (libyaml-clib, zlib-clib), cborg/serialise (GHC primops),
  skylighting-core's very large generated modules (compile time), and
  commonmark, texmath, citeproc and typst, all untried.

## Big remaining items

**Correctness and conformance**

1. Agda's Succeed failures include memory faults (`Eq NotBlocked'` from
   `compactDef`): miscompilations, the most serious kind.
2. GADTs are typed by coercing right-hand sides (existentials.mumble's
   soft unification), not with local equality assumptions (OutsideIn).
   Each new pattern of use needs a special case (QuickCheck's
   `abstract (Pair p) d (x,y)`, 2026-11-02).  Real given equalities
   would end that.
3. `Int` is 63 bits; GHC's is 64.  Report-conforming but not
   GHC-conforming: hashes, bit tricks and overflow differ.  Decided
   (2026-11-02): the default stays SBCL's fixnum, since a non-native
   representation would cost every numeric program; GHC's 64-bit `Int`
   is an opt-in, behind a flag or language extension for conformance.
4. Module names are global, not per package: PackageImports and two
   packages with the same module name fail (ansi-wl-pprint).
5. The library's partial packages hide the real ones: packages that
   import `.Internal` modules fail (QuickCheck was fixed by fetching it
   in full, `replacedPackages`; containers, text and bytestring
   internals are the likely next).
6. Unboxed types are boxed aliases (`Int#` is `Int`); Template Haskell
   is partial; no quasi-quotes.

**Speed**

1. Compile time is the worst gap: lens never finishes, nhc98's build
   stalls over 50 minutes on one unit, aeson's first build takes about
   3 minutes.  Likely a super-linear pass on large code; it would also
   block skylighting.
2. Run time: dictionary passing in recursive overloaded code (the main
   loss), SpecConstr, CPR and unboxed returns, worker/wrapper's absent
   arguments, garbage collection; 68 MB executables.

## Compile-time audit (item 1)

Found and fixed 2026-11-03 (all commands now run under `tools/bound`,
since `perl alarm` does not stop yale-haskell):

- Given equalities that reduce a family application in a cycle (lens's
  Control.Lens.Tuple, 14 hours): 15e5eae.
- A variable's only reference inside its own value inlined into itself,
  doubling the code every optimizer pass (nhc98's FixSyntax, 50 minutes
  and out of memory): bf3ef58.  It also made vector's modules 3x slower
  to compile (Data.Vector.Strict 62 s to 19 s; lens's check 7.5 to 2.6
  minutes).
- Lifting thunks out of oversized functions walked a refused body again
  at each enclosing level: 63b0e2e.
- A growth guard in the optimizer (d5c5731): it stops, with a warning
  naming the biggest bindings, when the code grows by half in three
  passes in a row past 10,000 nodes.

Next, the same kind of check for the other loops that run to a fixpoint:
strictness.mumble's fixpoint, mp-classes.mumble's improve-mp-loop (a
limit of 50 passes, no warning), import-export's and derived-instances'
fixpoints, and unify's deferred family equalities; each should count its
rounds and say so when a limit is reached.  The slowest units left are
SBCL compiling large generated code (vector's modules, about 20 s each,
half of it the interface file).

## Order

| # | Item | Status |
|---|---|---|
| 1 | Compile-time blowup: find it with lens and nhc98 | lens's loop and nhc98's stall fixed (2026-11-03, below); audit continues |
| 2 | A harness for GHC testsuite `should_run` tests: a conformance number | |
| 3 | Agda's memory faults | |
| 4 | basement/memory, then crypton, then pandoc's tree | |
| 5 | A batch of user programs against GHC's output | |
| 6 | Longer: opt-in 64-bit Int (never the default), local equality constraints, per-package module names | |
