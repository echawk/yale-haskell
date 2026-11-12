# Ticket board

The live status of every ticket. Full specs are in [`roadmap.md`](roadmap.md) §8.

**Status values:** `todo` · `in-progress` · `review` · `changes-requested` · `done` · `blocked`

**Who edits what:**
- Builders change only their own ticket's row: `todo → in-progress → review`,
  or `blocked`.
- Reviewers set `changes-requested`, or approve. On approval the reviewer merges
  the branch into `ng` with `--no-ff` and sets `done`. Reviewers also update
  `GATE-N` rows.
- A ticket is **eligible** when its status is `todo` and every ticket it depends
  on is `done`. Builders take the lowest-numbered eligible ticket, following the
  roadmap's **Execution order** (0 → 1 → 2 → {3 ∥ 4} → 5 → 6 → 7).
- **Never push.** Ticket branches stay local. The human pushes `ng` to run CI.

**Parallel tracks:** after GATE-2, Track K (Milestone 3) and Track P (Milestone
4) are independent; run one builder per track.

**Setup notes:**
- These files already exist and tickets extend them, never recreate them:
  `AGENTS.md`, `CLAUDE.md`, `doc/harness/*`, `notes/`, `.claude/skills/*`,
  `README.md`, `.gitignore` and `.editorconfig`.
- Baseline (2026-11-12, SBCL 2.6.10):
  - `make test`: 925 passed, 0 failed.
  - Haskell 1.2: 20 passed.
  - `make embed-test`: 2 passed.
  - `make liquid-test`: hung in Z3 (YHS-0.2).
  - CI has been red for 40 runs (YHS-0.1).
- `tools/microcabal/MicroCabal` is a submodule pinned at 60337f9 and is not
  initialised in the setup checkout. YHS-0.5 handles it.
- The harness setup is one commit on branch `harness/setup`. The managing agent
  merges it into `ng`.

## Milestone 0 — Baseline and hygiene

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-0.1 | Fix CI | — | review | Branch `ticket/YHS-0.1-fix-ci`; note `notes/YHS-0.1.md`. Owns the "verify" on the CI cause. Never push; CI green is confirmed after the human pushes `ng`. |
| YHS-0.1a | Linux CI failures after YHS-0.1 | YHS-0.1 | review | Run 43167422525: errno table and z3 fixed; `system/stack-overflow` memory fault on Linux still open. |
| YHS-0.2 | Z3 query timeout in yale-liquid | — | review | Branch `ticket/YHS-0.2-z3-timeout`; note `notes/YHS-0.2.md`. Hanging query: `tests/liquid/fq/pos/hex.ts.fq`. |
| YHS-0.3 | `scripts/check.sh` | YHS-0.1, YHS-0.2 | todo | CI must call this script. |
| YHS-0.4 | Ratchet counters | YHS-0.3 | todo | Mallet on mumble macros is **verify**. |
| YHS-0.5 | Submodule in setup docs and tests | YHS-0.3 | todo | Tests skip with a message when the submodule is absent. |
| YHS-0.6 | Stale facts | — | todo | Can start immediately; long run (extensions.py). |
| YHS-0.7 | ECL and ABCL baselines | — | todo | Long runs; ECL is slow. Counts are used at every gate. |
| YHS-0.8 | Conformance baselines | YHS-0.6 | todo | Creates `doc/harness/baselines.md`. |
| YHS-0.9 | Hermetic build check | — | todo | Owns the "verify" on the 12.6 s build. |
| GATE-0 | Milestone 0 gate | YHS-0.1–0.9 | todo | Needs the human's push of `ng` and green CI. |

## Milestone 1 — Correctness infrastructure

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-1.1 | Safe mode for program and library units | GATE-0 | todo | Cache key must include the safety level (north-star hook). |
| YHS-1.2 | Safe prelude image and full safe run | YHS-1.1 | todo | Findings become `1.2a`, `1.2b` ... rows. |
| YHS-1.3 | Typed-core lint | GATE-0 | todo | Spike: can FLIC after optimize be retyped? |
| YHS-1.4 | Metamorphic runner | GATE-0 | todo | Every pass must be switchable by name (north-star hook). |
| YHS-1.5 | Coverage floor with sb-cover | GATE-0 | todo | Does sb-cover see mumble code? **verify** |
| YHS-1.6 | Wire correctness tools into check and CI | YHS-1.2, YHS-1.3, YHS-1.4, YHS-1.5 | todo | Updates the `correctness` skill. |
| GATE-1 | Milestone 1 gate | YHS-1.1–1.6 | todo | |

## Milestone 2 — Miscompilations (Agda faults and the fuzzer)

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-2.1 | Reproducible Agda build and Succeed run | GATE-1 | todo | Needs the submodule; set `CABALDIR` under `build/`. Long run. |
| YHS-2.2 | Agda faults under safe mode | YHS-2.1 | todo | |
| YHS-2.3 | Minimise and fix the first Agda miscompilation | YHS-2.2 | todo | Expected output from GHC. More faults become `2.3a` ... rows. |
| YHS-2.4 | Random program generator v1 | GATE-1 | todo | Spike chooses Haskell+QuickCheck or Python. Seeds must be reproducible. |
| YHS-2.5 | Fuzz runner, oracle and reducer | YHS-2.4 | todo | Uses the metamorphic configurations from YHS-1.4. |
| YHS-2.6 | Fuzzer in CI | YHS-2.5 | todo | |
| GATE-2 | Milestone 2 gate | YHS-2.1–2.6 | todo | |

## Milestone 3 — Conformance number and compile time (Track K)

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-3.1 | GHC-testsuite baseline and categories | GATE-2 | todo | Create `ref/ghc-testsuite` with the `ref/README.md` recipe. Long run. |
| YHS-3.2 | Triage failures | YHS-3.1 | todo | Report only. |
| YHS-3.3 | Fix failure cause #1 from YHS-3.2 | YHS-3.2 | todo | The reviewer renames the row after triage. |
| YHS-3.4 | Fix failure cause #2 from YHS-3.2 | YHS-3.2 | todo | The reviewer renames the row after triage. |
| YHS-3.5 | Fixpoint round counters | GATE-2 | todo | |
| YHS-3.6 | Compile-time benchmark | GATE-2 | todo | Cold unit cache: set `YALE_HASKELL_CACHE_DIR` to a fresh directory. |
| GATE-3 | Milestone 3 gate | YHS-3.1–3.6 | todo | |

## Milestone 4 — Pandoc chain I: basement, memory, crypton (Track P)

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-4.1 | basement builds | GATE-2 | todo | Fix name resolution, not a patch, unless justified. |
| YHS-4.2 | memory builds | YHS-4.1 | todo | |
| YHS-4.3 | crypton survey | YHS-4.2 | todo | Report only; refines 4.4 and 4.5. |
| YHS-4.4 | crypton builds | YHS-4.3 | todo | |
| YHS-4.5 | tls and http-client-tls build | YHS-4.4 | todo | No real network connections in tests. |
| GATE-4 | Milestone 4 gate | YHS-4.1–4.5 | todo | |

## Milestone 5 — Pandoc chain II and user programs

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-5.1 | Pandoc closure status | GATE-4 | todo | Report only. |
| YHS-5.2 | Template Haskell packages | YHS-5.1 | todo | Through `src/compiler/th/` (north-star hook). |
| YHS-5.3 | C-library packages | YHS-5.1 | todo | |
| YHS-5.4 | commonmark and texmath | YHS-5.1 | todo | |
| YHS-5.5 | User-program batch harness | GATE-3 | todo | Corpus licensing is an open decision. Provenance file required. |
| YHS-5.6 | Fix top user-program failure causes | YHS-5.5 | todo | |
| GATE-5 | Milestone 5 gate | YHS-5.1–5.6 | todo | |

## Milestone 6 — Runtime performance I

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-6.1 | Performance baseline | GATE-5 | todo | Quiet machine; all numbers from one session. |
| YHS-6.2 | One-object thunks | YHS-6.1 | todo | Metamorphic and fuzz evidence required; may split into `6.2a`/`6.2b`. |
| YHS-6.3 | Demand analysis: absence | YHS-6.1 | todo | Metamorphic and fuzz evidence required. |
| YHS-6.4 | Demand analysis: strict constructor fields | YHS-6.3 | todo | Metamorphic and fuzz evidence required. |
| GATE-6 | Milestone 6 gate | YHS-6.1–6.4 | todo | |

## Milestone 7 — Runtime performance II

| ID | Title | Depends on | Status | Branch / notes |
|---|---|---|---|---|
| YHS-7.1 | CPR and worker/wrapper with `values` | GATE-6 | todo | Metamorphic and fuzz evidence required. |
| YHS-7.2 | Case-of-case with join points | GATE-6 | todo | Metamorphic and fuzz evidence required. |
| YHS-7.3 | Performance write-up | YHS-7.1, YHS-7.2 | todo | |
| GATE-7 | Milestone 7 gate | YHS-7.1–7.3 | todo | |
