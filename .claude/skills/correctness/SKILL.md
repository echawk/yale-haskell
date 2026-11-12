---
name: correctness
description: Yale Haskell's correctness tooling and ratchets (doc/harness/roadmap.md §7b): safe mode (safety 3 generated code), typed-core lint, the metamorphic runner (optimizer/back-end configurations must agree), the random-program fuzzer differential-tested against GHC, SBCL-warning / ocicl lint / Mallet / xfail / coverage ratchets, and how to justify a suppression. Use whenever a ticket touches src/compiler/backend, flic, grin, typed or type, adds an .xfail or suppression, or works on M1/M2 correctness tickets.
---

# correctness

Several tools below are built by Milestone 1 and 2 tickets. Before a tool's
ticket is `done`, use what exists: `make test`, the conformance runners, and
manual configuration runs. The ticket that builds a tool replaces its "planned"
note with the real command.

## Principles (non-negotiable)
1. **GHC is the oracle.** Agreement with GHC 9.14.1 (or the Report) is the
   definition of correct output.
2. **Configurations must agree.** A program's output must be the same under the
   default pipeline, `-O`, `--backend flic` and `-g none`. A difference is a
   miscompilation, even if the default output is right.
3. **Strictness only goes up.** Ratchet counts never rise. Lowering one means
   updating `scripts/ratchet-baseline.txt` in the same ticket.
4. **No silent suppressions.** Every `sb-ext:muffle-conditions`, lint ignore or
   new `.xfail` carries a comment `;; <reason> (YHS-N.n)`, and the reviewer
   approves it in the review note.
5. **Reduce before you fix.** A miscompilation found by Agda, the fuzzer or a
   runner is first reduced to a small test program with GHC-derived output, then
   fixed.

## Tools

| Tool | Command | Status |
|---|---|---|
| Ratchet counters | `scripts/check.sh --ratchet` | Planned in YHS-0.4. Counts SBCL WARNING/STYLE-WARNING per build log, `ocicl lint` per directory, Mallet, `.xfail` files, typed-core disagreements, metamorphic mismatches and the coverage floor. |
| SBCL warnings | `grep -c 'caught WARNING' build/sbcl/logs/compiler.log` | Available. Baseline 2026-11-12: compiler.log 4 WARNING / 3 STYLE-WARNING; haskell98-image.log 0 / 19. |
| `ocicl lint` | `ocicl lint src/liquid` (`.lisp` only; ignores `.mumble`) | Available. 691 findings in `src/liquid` on 2026-11-12. Do not run `--fix` across files outside your ticket. |
| Mallet | `mallet src` | Not installed; YHS-0.4 decides (**verify** handling of mumble macros). |
| Safe mode | `YALE_HASKELL_SAFETY=3 bin/yale-haskell F.hs`; `make SAFE=1 test` | Planned in YHS-1.1 and YHS-1.2. Uses code quality 0 (`safety 3`) from `src/mumble/cl-definitions.lisp`. |
| Typed-core lint | `YALE_HASKELL_LINT=1 tests/run-tests ...`; census: `tools/typed-core.py -v` | The census is available now. The lint is planned in YHS-1.3. |
| Metamorphic runner | `tools/conformance/metamorphic.py -j 8 PATH...` | Planned in YHS-1.4. Until then, run the configurations by hand (below). |
| Coverage | `make coverage` (sb-cover) | Planned in YHS-1.5. |
| Fuzzer | `tools/fuzz/run --seed S --count N` | Planned in YHS-2.4 to YHS-2.6. Interface fixed by that ticket. |

**Manual configuration check** (until YHS-1.4):
```sh
tools/bound 120 bin/yale-haskell T.hs                > out.default.txt
tools/bound 120 bin/yale-haskell -O T.hs             > out.noopt.txt
tools/bound 120 bin/yale-haskell --backend flic T.hs > out.flic.txt
tools/bound 120 bin/yale-haskell -g none T.hs        > out.nogrinopt.txt
ghc -O0 -outputdir build/ghc-T -o build/ghc-T/T T.hs && build/ghc-T/T > out.ghc.txt
```
All outputs must be identical.

## Writing a reduced test from a miscompilation
1. Save the failing program, the configuration and both outputs in
   `notes/<ID>/`.
2. Shrink by hand or with the fuzzer's reducer. Delete definitions, inline
   constants and shorten lists, keeping the discrepancy, until the program is
   under 150 lines.
3. Generate `.stdout` with GHC. Add `.flags` if the bug needs a flag.
4. If the fix is not in this ticket, add `.xfail` naming the fixing ticket.

## Evidence per rung (what reviewers look for)
- **Optimizer and back ends:**
  - the regression test;
  - a metamorphic run over `tests/haskell98/language` with no new mismatch;
  - after YHS-2.6, a fuzz run of 1,000 or more programs with the seed recorded;
  - typed-core lint count not raised.
- **Type checker:** positive and negative tests; `tools/conformance/extensions.py`
  probe count not lowered.
- **Runtime:** tests pass in safe mode (after YHS-1.2).
- **Lisp infrastructure:** ratchet passes.

## Pitfalls
- `Int` wraps modulo 2^63 in Yale and 2^64 in GHC. Fuzzer programs and test
  programs must stay within ±2^62, or a difference is expected, not a bug.
- Output under `--haskell1.2` uses Dialogue I/O. Do not compare it with GHC.
- Safe mode compiles slower. Use `-j` and `tools/bound`. Never leave the default
  build in safe mode.
- SBCL notes (`note:`) are optimization hints, not warnings. The ratchet counts
  WARNING and STYLE-WARNING only.
