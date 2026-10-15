# Mission: improve Yale Haskell — conformance and performance

You are taking over active development of **Yale Haskell**, a Haskell
compiler originally written at Yale in 1994 (Y2.0.5, Haskell 1.2) in
"mumble", a Scheme-flavoured Lisp dialect on Common Lisp. It has been
revived on SBCL and, over the last month, brought to full Haskell 98,
Haskell 2010, modern base, and a large set of GHC extensions, with
several real-world Haskell programs now running unchanged.

Your goal: **make the highest-value progress on (1) Haskell
conformance and (2) performance of generated code.** Do not redesign
the architecture; this codebase is a complete, working, readable
pipeline, and the plan is to keep it.

Work in the repository at the root of this session. Before changing
any code, read, in this order:
- `README.md` (build/run/usage), `doc/REVIVAL-PLAN.md` (history, open
  bugs, long-term direction), `doc/STRATEGY.md` (per-feature file map,
  tests, invariants);
- `doc/plans/README.md` and the specific plan you are working on
  (`CONFORMANCE.md`, `GHC-EXTENSIONS.md`, `GHC-OPTIMIZATIONS.md`,
  `SPECIALIZE.md`, `CUBICALTT.md`, `MICROCABAL.md`,
  `REAL-WORLD-TARGETS.md`, `PORTABILITY.md`; `FUTURE-TARGETS.md`
  lists later targets and is outside this mission);
- `bench/RESULTS.md` (every measured change so far, with numbers).

The documents are authoritative for *what is true today*; if a
document and the source disagree, believe the source and fix the
document.

---

## 1. What the system is

- The compiler is ~35,000 lines of mumble (`src/compiler/`, plus
  `src/runtime/`), which itself is a macro layer on plain Common Lisp
  (`src/mumble/`, ~6,300 lines). Generated Haskell becomes Common Lisp
  that SBCL (2.6, tested on arm64 macOS) compiles to native code.
  There is a Lisp FFI (`LispName` primitives in `.hi` files) and a C
  FFI through CFFI.
- Pipeline: `parse → import/export → tdecl → derived → prec/scope →
  depend → type → cfn → FLIC → optimize → strictness + box →
  grin-lower → grin-opt → grin-emit → SBCL`. `optimize` is an iterated
  rewrite walk (inlining, selector folding, dictionary-function
  folding, SPECIALIZE, foldr/build, case-of-case); `strictness` is
  Consel's fixpoint analysis; the GRIN back end (eval/apply, explicit
  laziness) is the default, and the old FLIC back end is selectable
  with `--backend flic`.
- Dialects: `haskell-1.2`, `1.3`, `1.4`, `haskell98`, `haskell2010`
  (flag `--haskell2010`), plus `--modern-prelude` (base-style
  Functor/Applicative/Monad/MonadFail/Semigroup/Foldable/Traversable
  prelude) and `--cpp` (built-in C preprocessor). **All dialect
  differences are gated by feature predicates** — `(feature? 'name)`
  over the table in `src/compiler/top/globals.mumble`. Never write raw
  `(haskell98?)` in new code; add a feature to the table.
- Key directories: `src/compiler/{parser,import-export,tdecl,derived,
  prec,depend,type,cfn,flic,backend,grin,csys,command-interface,top}/`,
  `src/runtime/`, `src/cli/`, `src/ffi/`, `lib/haskell-1.2/` and
  `lib/haskell98/` (the prelude and Data.*/Control.*/Foreign.*/GHC.*/
  System.* libraries), `tools/build/`, `tools/conformance/`,
  `bench/`, `tests/`, `doc/`.

## 2. Build, test, run

```sh
make                 # compiler, prelude, build/sbcl/yale-haskell executable
make test            # the regression suite (tests/run-tests; it prints the count)
bin/yale-haskell prog.hs                    # compile + run Main.main
bin/yale-haskell --haskell98 prog.hs a b    # H98 mode, args to getArgs
bin/yale-haskell --modern-prelude --cpp prog.hs   # modern base (implies --haskell2010)
bin/yale-haskell --haskell98 compile F.hs --emit scope,depend,cfn,flic,optimize,strictness,grin,codegen,lisp,asm
```

Conformance harnesses (GHC 9.14.1 is available for comparison):
- `tools/conformance/nofib.py` — nofib imaginary/spectral/real/shootout/gc;
- `tools/conformance/extensions.py` — one program per GHC extension, compared with GHC's output;
- `tools/conformance/h2010-exports.py` — 2010 Report export lists;
- `tools/conformance/{cubicaltt,typecheckers,happy,husk,darcs,xmonad}.py` — real-world targets;
- `bench/compare-ghc [-n N]` — every bench program under Yale and GHC -O0/-O2; the ratio column and the "Yale MB" (allocation) column are the primary metrics.

Debugging environment variables: `YALE_HASKELL_TIME=1` (phase times,
GC time, bytes allocated), `YALE_HASKELL_PROFILE=1` (sb-sprof of
main), `YALE_HASKELL_PROFILE=alloc`, `YALE_HASKELL_DEBUG=1`,
`YALE_HASKELL_NO_SPECIALIZE` / `_SPECIALIZE_LIMIT` / `_SPECIALIZE_TRACE`,
`YALE_HASKELL_NO_CASE_OF_CASE=1`, `YALE_HASKELL_NURSERY_MB`,
`YALE_HASKELL_CACHE=0`.

## 3. Current state (verified as of 2026-10-14, commit a28af4a)

- **Haskell 98 and 2010: done**, including records, qualified names,
  newtype, constructor classes, monadic IO, do, FFI (`foreign export`
  reached through `&name`, `"wrapper"` callbacks), pattern guards, CPP.
- **Modern base and GHC extensions: 101 of 104 probes pass** (GHC2021 +
  common non-2021 extensions + modern libraries; MPTC with fundeps,
  FlexibleInstances/Contexts, RankN, GADTs (permissive),
  TypeFamilies, DataKinds, PatternSynonyms (cross-module),
  Overloaded*, DeriveVia, overlapping instances, ConstraintKinds,
  RecursiveDo, ViewPatterns, …). Libraries beyond the Report:
  transformers, mtl, containers, array (ST/IO/Unboxed/IArray),
  parsec 3 (unchanged source), QuickCheck 2 subset, pretty,
  haskeline, time, filepath, GetOpt, Data.Text/ByteString (packed
  Lisp strings since 2026-10-14).
- **Real-world programs run unchanged** with output matching GHC 9.14:
  MicroCabal (`mcabal parse` agrees on 19 .cabal files), xmonad's core
  + 107 QuickCheck properties, darcs 1.0.9 (25-step session + unit
  tests), husk-scheme 3.20 (full test suites), happy 1.20.1.1 (166/166
  generated parsers byte-identical, incl. a 1,250-line grammar),
  cubicaltt 43/43 proof files, LambdaPi and Mini-TT.
- **Performance**: Haskell 98 bench programs are 1.5–3.5× GHC -O2;
  modern bench programs 2.7–5.3× (foldable 5.3×, starray 4.4×,
  statemonad 4.2×, mapcount 2.9×); cubicaltt: 4 of 6 heavy examples
  now match or beat GHC -O2, torsor 1.4×, grothendieck 2.2×, hz 2.8×,
  setquot 2.9×; LambdaPi 3.2× and Mini-TT 2.6×. Yale allocates
  1.5–1.6× GHC's bytes; SBCL's GC takes 2–7× the time GHC spends in
  its collector.

## 4. Conformance gaps (what is still missing)

Realistic, in rough order of value:

1. **Binary I/O**: done (`openBinaryFile`, `withBinaryFile`,
   `hSetBinaryMode` on standard and file handles, `hGetBuf`/`hPutBuf`;
   Latin-1 streams in `src/runtime/handle-prims.mumble`).
2. **A packed representation for Data.Text and Data.ByteString**: done
   2026-10-14 (both Lisp strings; a ByteString's characters are bytes;
   `src/base/text-runtime.lisp`). optparse-applicative's test suite
   passes (2026-10-15, `tools/conformance/optparse.py`); megaparsec next.
3. **Missing libraries** (mostly plain Haskell; clone into `ref/`,
   record workarounds as patches in `tools/conformance/<target>/`,
   never edit the clone): `vector` (boxed over Lisp simple-vectors, unboxed over
   specialized arrays; no stream fusion at first),
   `unordered-containers` + `hashable` (a Data.Map-backed
   implementation is acceptable behind the API),
   an `aeson` subset (no Generic), the rest of QuickCheck 2's API,
   real haskeline line editing. (`process` and `Data.Graph`: done
   2026-10-14.)
4. **`foreign export` and `"wrapper"` imports**: done (2026-10-14;
   trampoline pools in `src/ffi/ffi-runtime.lisp`, `doc/FFI.md`).
   Exports are reached through `&name`, not by the C linker.
5. **GHC departures**: `Num` without `Eq`/`Show` superclasses is
   followed under `--modern-prelude` (stub instances, 2026-10-14).
   `Int` stays the 63-bit fixnum, wrapping modulo 2^63 (nofib
   `sphere` deviates); a 64-bit `Int` was judged not worth its cost.
6. **Tightening the permissive type checker** (each has a probe in
   extensions.py): escape checks for existential and rank-N type
   variables, and local type refinement in GADT matches (right-hand
   sides are currently coerced instead). The cost today is that some
   programs GHC rejects are accepted — worth fixing only after 1–5.
7. **Catch-all instances** (`instance Show a => Pretty a`): done
   2026-10-14. The failing probes: GHCIntWraps (by choice), QuantifiedConstraints
   (medium-large), TemplateHaskell (out of scope; Arrows done 2026-10-15)
   for this mission — `doc/plans/FUTURE-TARGETS.md` §2 keeps it as
   a design question).
8. **Known runtime deviations**: datatype contexts, `Assoc`/`Bin` as
   user names and batch-mode diagnostics (stderr, exit 1) were already
   fixed when checked on 2026-10-14.

Also read the "Open bugs" list in `doc/REVIVAL-PLAN.md` §7 — some are
fixed, some are not; check each against the current tree before
dismissing it.

## 5. Performance: where the time goes, and what to build

Profiles (cubicaltt, LambdaPi, Mini-TT, nofib, bench/modern) show the
same story: **thunks and small data objects are too expensive, and
allocation drives GC time**. A thunk is a two-word cons plus a
closure; a 2+-field constructor is a vector with a tag word (one-field
constructors are already conses, arity-1 functions already bare
closures — that change alone was −18% allocation on LambdaPi).
The mutator is 1.6–2.4× GHC even before GC.

The ordered plan is `doc/plans/GHC-OPTIMIZATIONS.md` §3 ("What to
build, in order"). Its state: Specialize (done, 2026-10-11), library
inlining audit (mostly done), and the remaining items, in the order
they should be attempted:

1. **Smaller thunks**: one-object thunks — a funcallable instance or a
   closure with a mutable slot — replacing the cons+closure pair.
   Measure allocation (Yale MB) on LambdaPi/Mini-TT/torsor first.
2. **Demand analysis upgrades** in `backend/strictness.mumble`:
   absence (drop unused arguments in `/OPT`), strictness of
   constructor fields (strict `Int` inside a tuple), and strictness
   through the transformer-stack `>>=` these checkers use. This feeds
   the next item and cuts thunk creation.
3. **Worker/wrapper with CPR and unboxed returns via CL `values`**
   (`doc/EVAL-APPLY-GRIN.md` §5.4 items 3–4): functions that always
   return a known constructor (quotRem/divMod, IO results,
   State's `(a, s)` — statemonad allocates 418 MB) return fields
   unboxed. Also unboxed `Double` across calls and
   all-`Double`-field record layouts.
4. **Case-of-case with join points**: the current `let-case-of-case`
   handles bodies of ≤60 nodes; join points would lift that limit and
   compound with inlining (maybe, either, uncurry, when).
5. **SpecConstr**: specialize recursive functions for the constructor
   shapes at their recursive calls, sharing SPECIALIZE's copy/memo
   machinery. Candidates: queens (a thunk+cons per element),
   list-comprehension generators, tuple accumulators.
6. **Float in, then conservative full laziness** (constant expressions
   only), and **CSE** (structured constants are already shared).
7. **Usage analysis, update avoidance, and eager selection**: a
   single-entry thunk needs no update; and when the tuple is known
   evaluated, select the field eagerly instead of leaving a selector
   thunk — the fix for the classic `let (a,b) = e` space leak (GHC's
   GC does selector-thunk elimination; SBCL's cannot, so do it at
   compile time in `grin-opt`/`box`). The worst case, nofib `simple`'s
   4 GB leak, was already fixed on 2026-10-10 by making
   single-constructor patterns strict (`bench/RESULTS.md`); what
   remains is the lazy pattern-binding case, which still needs a
   program that shows it before it is worth building.
8. **A size-based inliner** for non-recursive functions under N FLIC
   nodes, counting argument shapes as GHC's unfolding discounts do —
   this would replace most explicit `Inline` annotations.
9. **General RULES** as an annotation (today only foldr/build are
   hard-wired in `optimize.mumble`).

Do not attempt (SBCL covers them or they don't apply): Cmm-level
passes, register allocation, pointer tagging, exitification, STG CSE,
real threading (the runtime is single-threaded; Control.Concurrent is
a one-thread approximation — a threaded runtime is a separate large
project), and Template Haskell.

## 6. Rules of the road (non-negotiable)

1. **`make test` must stay green after every change** (all dialects:
   haskell-1.2 and haskell98 tests; the 1.2 demos are a fixed
   regression baseline — do not break 1.2). New features get tests:
   `tests/<dialect>/...` with `.hs` + `.stdout`/`.exit` (+ optional
   `.stdin`, `.xfail`, `.flags`), following the existing conventions.
2. **Measure before and after every performance change** with
   `bench/compare-ghc -n 3` (quiet machine; compare numbers taken in
   the same session), plus the conformance harnesses that cover the
   affected area. Append a dated, numbered section to `bench/RESULTS.md`
   exactly like the existing ones. A performance change with no
   measured result should be dropped or reworked; a conformance
   change is measured by its tests and harness counts.
3. **Update the plan document** that covers your work
   (`doc/plans/*.md`, `CONFORMANCE.md` status tables,
   `GHC-OPTIMIZATIONS.md` status cells) when a step lands, and record
   what you measured and why.
4. **Keep generated code profilable**: readable `|Module:name|`
   symbols, no gratuitous gensym, `*code-quality*` (speed 3, safety 0)
   applied to program code as to the prelude.
5. **Host portability**: SBCL is the main host; keep new
   implementation-specific calls behind `#+` in `src/mumble/` or
   `src/runtime/` (ECL 193/200 and ABCL 162/200 must not regress).
6. **Real-world targets**: clone into `ref/` (gitignored), record
   workarounds as patches in `tools/conformance/<target>/` — never as
   edits to the clone — and keep `tools/conformance/<target>.py`
   green.
7. **License hygiene**: the H98/H2010 Report and Hugs (BSD) may be
   copied with notices kept; nhc98 is read-only (its libraries
   already ported where used); do not pull in copyleft code.
8. Prefer small, well-tested increments: one feature, one optimization
   pass, one library module at a time, each with tests + bench numbers
   + a doc update, in that order.
9. When in doubt about compiler internals, `doc/STRATEGY.md` gives the
   file-level map, and `--emit optimize,grin,lisp` (or `:grin`, `:lisp`
   in the REPL) shows what each pass produced for a given expression.

## 7. Suggested order of work

**Phase A — cheap conformance wins** (each is small-to-medium,
independent, and unblocks real programs):
A1. Binary I/O (§4.1). A2. `foreign export`/`"wrapper"` (§4.4).
A3. `process` and `Data.Graph` libraries (§4.3). A4. Batch-mode error
hygiene + datatype contexts + free `Assoc`/`Bin` (§4.8). (A1-A4: done
2026-10-14.)

**Phase B — the two big conformance items**:
B1. Packed Text/ByteString representation (§4.2) — then bring up
megaparsec and optparse-applicative as the proof.
B2. Catch-all instances, then the permissive-type-checker tightening
(escape checks, GADT refinement) (§4.7–4.6).

**Phase C — performance, in the §5 order**:
C1. Smaller thunks (§5.1). C2. Demand analysis upgrades (§5.2).
C3. Worker/wrapper + CPR with `values` (§5.3). C4. Case-of-case with
join points, SpecConstr, float-in/CSE, size-based inliner, RULES
(§5.4–5.6, 5.8–5.9). Eager selection (§5.7) when a program shows
the remaining `let (a,b) = e` leak.

Success looks like: `make test` green, `nofib.py --try-all` at or
above 69 imaginary/spectral and 40 real/gc/shootout with no failures
(the counts in GHC-EXTENSIONS.md's status table),
`extensions.py` with at most 4 failures (3 of 104 since 2026-10-15:
Int wrap-around, QuantifiedConstraints, TemplateHaskell), and `bench/compare-ghc` ratios for the
modern bench programs (foldable, mapcount, statemonad, starray)
reduced toward 2×, with LambdaPi/Mini-TT and cubicaltt torsor/grothendieck
at or below 2× — every number appended to `bench/RESULTS.md`.
