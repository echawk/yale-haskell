---
name: perf-change
description: How to make and prove a runtime-performance or allocation change in Yale Haskell. Covers measuring with bench/compare-ghc -n 3 before and after in one quiet session, LambdaPi/Mini-TT/cubicaltt allocation, profiling (YALE_HASKELL_PROFILE, make profile), appending a dated section to bench/RESULTS.md, and the correctness evidence an optimization needs. Use for any ticket that changes src/compiler/backend, flic, grin or src/runtime for speed, or claims a speed or allocation result.
---

# perf-change

## Principles (non-negotiable)
1. **Measure before and after, in the same session, on a quiet machine.** Use
   `bench/compare-ghc -n 3`. Numbers from different sessions are not compared.
2. **No measured gain, no merge.** A change with no measured improvement is
   dropped or reworked (AGENTS.md §4 rule 6).
3. **Correctness first.** Every optimization needs:
   - metamorphic agreement with the pass on and off;
   - after YHS-2.6, a fuzz run of 1,000 or more programs (`correctness` skill);
   - `make test` green.
4. **Every new pass can be switched off by name** (`--optimizers -name` or
   `-g -name`).
5. **Generated code stays profilable:** readable `|Module:name|` symbols, and
   `*code-quality*` applied as to the prelude.

## Measuring
```sh
bench/compare-ghc -n 3                 # all bench programs: Yale vs GHC -O0/-O2; ratio and Yale MB
bench/compare-ghc -n 3 queens tree     # a subset: bench/NAME.hs or bench/modern/NAME.hs
YALE_HASKELL_TIME=1 bin/yale-haskell bench/tree.hs     # phase times, GC time, bytes allocated
YALE_HASKELL_PROFILE=1 bin/yale-haskell prog.hs        # sb-sprof of main
YALE_HASKELL_PROFILE=alloc bin/yale-haskell prog.hs    # allocation profile
make profile FILE=prog.hs
```
- The primary metrics are the **ratio** column and **Yale MB** (allocation).
- For thunk and demand work, also measure LambdaPi, Mini-TT and cubicaltt
  torsor/grothendieck (`tools/conformance/cubicaltt.py`,
  `tools/conformance/typecheckers.py`). These need their `ref/` clones (see the
  `conformance-target` skill).
- Close other heavy processes. Record the machine and SBCL version.

## Recording
Append a section to `bench/RESULTS.md` in the same style as the existing ones:
- a heading `## <change> (YYYY-MM-DD)`;
- what changed and why;
- a before/after table from the same session;
- allocation;
- anything that got slower, and why it is accepted.

Update the status cell in `doc/plans/GHC-OPTIMIZATIONS.md`.

## Where things are
- Ordered plan and background: `claude-prompt.md` §5 and
  `doc/plans/GHC-OPTIMIZATIONS.md` §3.
- GRIN design: `doc/EVAL-APPLY-GRIN.md`.
- Optimizer: `src/compiler/backend/optimize.mumble`.
- Strictness: `src/compiler/backend/strictness.mumble`.
- Boxing: `backend/box.mumble`.
- GRIN passes: `src/compiler/grin/`.
- Do not attempt (from `claude-prompt.md` §5): Cmm-level passes, register
  allocation, pointer tagging, exitification, STG CSE, real threading or
  Template Haskell as performance work.

## Testing (required)
- A regression test whose output depends on the optimized code path, with
  GHC-derived output.
- Metamorphic agreement over `tests/haskell98/language` and `tests/haskell98/lib`.
- Fuzz evidence (after YHS-2.6), with the seed recorded in the handoff note.
- `bench/RESULTS.md` section committed on the ticket branch.

## Pitfalls
- GC time on SBCL varies between runs (statemonad varied from 1.8× to 5.6×). Use
  `-n 3` and report the spread.
- The unit cache can hide recompilation. Use a fresh `YALE_HASKELL_CACHE_DIR`
  when measuring compile-time effects.
- Size limits exist for a reason. The optimizer's growth guard (10,000 nodes)
  and the case-of-case limit (60 nodes) prevent compile-time blowups
  (`doc/plans/ROADMAP.md` "Compile-time audit").
