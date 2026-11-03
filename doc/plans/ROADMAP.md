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
   GHC-conforming: hashes, bit tricks and overflow differ.  A 64-bit
   Int costs speed (SBCL fixnums are 63 bits).
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

## Order

| # | Item | Status |
|---|---|---|
| 1 | Compile-time blowup: find it with lens and nhc98 | in progress (2026-11-02) |
| 2 | A harness for GHC testsuite `should_run` tests: a conformance number | |
| 3 | Agda's memory faults | |
| 4 | basement/memory, then crypton, then pandoc's tree | |
| 5 | A batch of user programs against GHC's output | |
| 6 | Longer: 64-bit Int, local equality constraints, per-package module names | |
