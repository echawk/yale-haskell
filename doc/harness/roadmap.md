# Yale Haskell: ticketed roadmap for correctness, conformance and speed

Ticket prefix `YHS`. Repository: `ssh://git@github.com/echawk/yale-haskell`,
main line `ng`. This file is the plan of record (human decision, 2026-11-12).
The design documents in `doc/plans/` stay as references that tickets link to.

## 1. One-paragraph summary

Yale Haskell is the 1994 Yale Haskell compiler revived on SBCL. It is written in
*mumble*, a Scheme-flavoured macro layer over Common Lisp. It compiles Haskell 98,
Haskell 2010, GHC2021 and GHC2024, plus most GHC extensions, to Common Lisp. SBCL
then compiles that Lisp to native code. It ships a Haskell 1.2 dialect, a C FFI,
a LiquidHaskell-style refinement checker (`src/liquid/`, using Z3), and builds
about 80–160 Hackage packages through MicroCabal. Agda's dependencies are among
them. This roadmap turns the next phase of work into small tickets that cheap
builder agents can implement and stronger reviewer agents verify. The phase
covers four things. First, an honest baseline: CI green, a check script and
ratchets. Second, correctness infrastructure that finds miscompilations: safe-mode
runs, typed-core lint, metamorphic runs and a random-program fuzzer. Third,
conformance: GHC's testsuite number, the compile-time audit, the pandoc dependency
chain and a batch of user programs. Fourth, runtime performance. The single most
important principle is that **output must match GHC's**. Every behaviour is
checked against GHC 9.14.1 or the Haskell Report, never against what Yale
Haskell printed yesterday. A faster compiler that is wrong is a regression.

## 2. Decisions already made

| Topic | Decision |
|---|---|
| Duration | Open-ended, solo plus agents. About 8 milestones (0–7), with a gate every 1–2 weeks. (Human decision, 2026-11-12.) |
| Language / stack | Unchanged: mumble on Common Lisp, SBCL 2.6.x as the main host, with ECL and ABCL as secondary hosts. The architecture and pipeline order are kept (`doc/STRATEGY.md` invariant 1). |
| Plan of record | This file. The order table in `doc/plans/ROADMAP.md` and §7 of `claude-prompt.md` are marked "Superseded by doc/harness/roadmap.md". The rules in `claude-prompt.md` §6 now live in `AGENTS.md`. (Human decision, 2026-11-12.) |
| Harness location | `doc/harness/` (roadmap, board, protocol), to match the repository's `doc/` convention. Notes go in top-level `notes/` (§4.2). (Human decision, 2026-11-12, for `doc/harness/`; `notes/` placement chosen at setup.) |
| Scope | In scope: correctness first (Agda's memory faults, the GHC-testsuite number, the compile-time audit); the pandoc dependency chain and the user-program batch; runtime performance (smaller thunks, demand analysis, CPR and worker/wrapper, join points). Out of milestone scope: opt-in 64-bit `Int`, local equality constraints (OutsideIn) and per-package module names. These are stretch goals and north-star hooks only. (Human decision, 2026-11-12.) |
| CI | Milestone 0 fixes CI: `ocicl install`, SBCL 2.6.x pinned on both runners, `ocicl/` cached, submodule initialised. CI calls `scripts/check.sh`. (Human decision, 2026-11-12.) |
| Host Lisps | SBCL must stay green on every ticket. ECL and ABCL are checked at every milestone gate against the counts recorded by YHS-0.7. (Human decision, 2026-11-12.) |
| Gate evidence | `make test` counts for both dialects, plus `make embed-test` and `make liquid-test`. Conformance runner counts: extensions, nofib, the GHC testsuite and the real-world targets touched. `bench/compare-ghc -n 3` tables appended to `bench/RESULTS.md`. (Human decision, 2026-11-12.) sb-cover is not gate evidence; it is only the coverage-floor ratchet. |
| Correctness level | All three tiers adopted: (1) the tiered core: safe-mode run, typed-core lint, metamorphic runs and an SBCL-warning ratchet; (2) a random well-typed program generator, differential-tested against GHC; (3) lint and coverage ratchets: `ocicl lint` and Mallet with today's counts as the baseline, plus an sb-cover coverage floor. See §7b. (Human decision, 2026-11-12.) |
| MicroCabal submodule | Part of the baseline. Milestone 0 adds `git submodule update --init` to the setup docs and CI. Tests that need it skip with a message when it is absent. (Human decision, 2026-11-12.) |
| Git, merges and pushes | Reviewer merges approved tickets into ng automatically; agent branches stay local and are never pushed; the human pushes ng to run CI. (Human decision, 2026-11-12.) The reviewer merges with `--no-ff` as soon as it approves. CI results therefore come only from the human's pushes of `ng`. The setup branch `harness/setup` is merged by the managing agent after the setup report. |
| Agent workflow | Ticketed milestones with reviewer gates: a cheap builder, a stronger reviewer and human sign-off (see `doc/harness/agent-protocol.md` and `AGENTS.md`). (Human decision, 2026-11-12.) |
| Commit style | The repository's existing style is a plain sentence summary. Ticket commits keep it and prefix the ticket ID, e.g. `YHS-1.2: safe-mode prelude image`. (Chosen at setup; the human may override.) |

**Execution order:** 0 → 1 → 2 → {3 ∥ 4} → 5 → 6 → 7. After GATE-2, Milestone 3
(conformance and compile time) and Milestone 4 (pandoc chain I) are independent
tracks; run one builder per track. Milestone 6 (performance) follows GATE-5 in
this order. It must never start before GATE-2, so that the fuzzer and the
metamorphic runner exist before the optimizer changes. If the human moves
performance earlier, the floor is GATE-2.

## North-star goal (not in current scope)

**Dream: Yale Haskell is a drop-in GHC replacement for real code, with evidence.**
The dream has four parts, all of them checkable:

1. **Pandoc** builds from Hackage with Yale Haskell, and its test suite passes
   with output identical to GHC's.
2. **Agda's Succeed suite passes 1852 of 1852** (1183 of 1852 on 2026-10-27,
   `doc/plans/ROADMAP.md`).
3. **GHC `should_run` parity:** every GHC 9.14.1 `compile_and_run` test that does
   not depend on GHC internals passes (`tools/conformance/ghc_testsuite.py`).
4. **Zero known miscompilations:** the random-program fuzzer (YHS-2.4) runs clean
   for millions of programs across every optimizer configuration.

No ticket implements these. **Do not build them now.** Do make the design choices
below so they stay feasible. Reviewers reject changes that close these doors.

| Design hook | Applies to | Why it matters for the dream |
|---|---|---|
| Patches for third-party packages live only in `tools/microcabal/patches/` or `tools/conformance/<target>/`, one file per package, never as edits to a clone. | 2.1–2.3, 4.*, 5.* | Pandoc (part 1) needs about 190 packages. Patches must be reviewable and droppable as Yale improves. |
| New code makes no fresh assumption that module names are global. Look modules up through the existing unit and package functions, not new global tables keyed by bare module name. | 4.*, 5.*, 3.* | Per-package module names (stretch) are needed for pandoc's tree and `PackageImports` (part 1). |
| New Template Haskell support goes through `src/compiler/th/`, not special cases in package patches. | 5.2 | file-embed and th-lift sit in pandoc's closure (part 1). |
| The Agda build and its Succeed run are scripted and reproducible (`tools/conformance/agda.py`, YHS-2.1). | 2.1–2.3 | Part 2 is a number that must be re-measured at every gate. |
| Safe mode (YHS-1.1, YHS-1.2) works for whole package builds, and the unit cache is keyed by safety level. | 1.1, 1.2, 2.1 | Memory faults in Agda (part 2) are found by running Agda's code at safety > 0. |
| `ghc_testsuite.py` keeps a machine-readable `results.tsv` with a stable column set and categorised SKIP reasons. | 3.1–3.4 | Part 3 is tracked as a count over time; categories show what is left. |
| New code never hard-codes the 63-bit fixnum width. Use a named constant or the existing `Int` bounds definitions. | all | An opt-in 64-bit `Int` (stretch, decided 2026-11-02) must stay possible; GHC parity (part 3) depends on it. |
| Every optimizer pass can be switched off by name (`--optimizers -name`, `-g -name`), and new passes are registered the same way. | 1.4, 6.*, 7.* | The metamorphic oracle and the fuzzer (part 4) compare configurations; a pass that cannot be switched off cannot be isolated. |
| The typed core (`src/compiler/typed/`) accepts every new IR construct a ticket adds. | 1.3, 6.*, 7.* | Typed-core lint is the per-pass oracle for part 4. |
| Fuzzer runs are reproducible from a seed, and each discrepancy is saved with its seed and configuration. | 2.4–2.6 | Part 4 needs "clean for N programs" to be a reproducible claim. |
| GADT and existential typing changes keep the type checker's soft-unification entry points in one place (`src/compiler/type/existentials.mumble`). | any type-checker ticket | Local equality constraints (OutsideIn, stretch) would replace them in one place. |

Stretch goals (from `doc/plans/ROADMAP.md` item 6, not in milestone scope): an
opt-in 64-bit `Int` (never the default), local equality constraints, and
per-package module names. They enter the roadmap only through a `roadmap/<slug>`
branch and a dated human decision.

## 3. Current state: facts the agents must know

- **Pipeline:** `parse → import/export → tdecl → derived → prec/scope → depend →
  type → cfn → FLIC → optimize → strictness + box → grin-lower → grin-opt →
  grin-emit → SBCL` (`claude-prompt.md` §1, `doc/STRATEGY.md`). The GRIN back end
  is the default; `--backend flic` selects the old one.
- **Entry points:**
  - `bin/yale-haskell` links to `build/sbcl/haskell98/yale-haskell`, a saved SBCL
    image. The command line is in `src/cli/`.
  - The Makefile drives the `tools/build/*.lisp` steps.
  - `src/compiler/system.mumble` loads the compiler.
- **Baseline verified on 2026-11-12** (Apple arm64, Darwin 27.0; SBCL 2.6.10,
  ocicl 2.20.0, GHC 9.14.1, Z3 5.3.3, ECL 26.5.5, Python 3.15.2, GNU Make 3.81):
  - `make deps` OK (3.9 s); `make` OK (12.6 s).
  - `make test`: **925 passed, 0 failed, 0 expected failures, 0 unexpected
    passes** (4 min 58 s).
  - `make haskell-1.2`, then `tests/run-tests tests/haskell-1.2`: **20 passed,
    0 failed**.
  - `make embed-test`: **2 passed, 0 failed**.
  - `make liquid-test`: **tainted**. A `z3 -smt2 -in` process ran at 100% CPU
    for more than 9 minutes while SBCL waited. After z3 was killed the run
    printed `OK: 0 failures (65 unit checks)` and `neg: 38/39 UNSAFE (1 listed as
    expected failures)`. One query has no timeout; YHS-0.2 owns this.
  - ECL and ABCL were not run. `doc/plans/PORTABILITY.md` records ECL 193/200
    and ABCL 162/200 from 2026-10-09, when the suite had 200 tests. YHS-0.7
    re-measures them.
- **The build is suspiciously fast** (12.6 s for the compiler, prelude and
  image). It may reuse an ASDF fasl cache outside the repository. **Verify in
  YHS-0.9.**
- **CI is red.** The last 40 GitHub Actions runs on `ng` failed (checked
  2026-11-12 with `gh run list`). The latest failure is the `haskell98-image`
  step; every test then exits 127. Probable causes: `ci.yml` never runs
  `ocicl install`, and Ubuntu 24.04's apt SBCL is 2.2.9. **Verify in YHS-0.1.**
- **Build warnings (2026-11-12):**
  - `build/sbcl/logs/compiler.log`: 4 `caught WARNING` (undefined variables
    `*CODE-QUALITY*` and `*MUMBLE-READTABLE*`) and 3 `caught STYLE-WARNING`.
  - `haskell98-image.log`: 19 STYLE-WARNINGs and 750 notes.
- **Lint baseline:** `ocicl lint src/liquid` reports 691 findings. `ocicl lint`
  ignores `.mumble` files ("Scanned 0 files").
- **Conventions:**
  - Dialect differences go through `(feature? 'name)` and the feature table in
    `src/compiler/top/globals.mumble`.
  - SBCL-specific calls go only behind `#+sbcl` in `src/mumble/` or
    `src/runtime/`.
  - Generated Lisp keeps readable `|Module:name|` symbols.
  - Interface files round-trip (`doc/STRATEGY.md` §"Cross-cutting invariants").
- **Tests:** `tests/<dialect>/<area>/<name>.hs` with `.stdout`, `.exit`,
  `.stdin`, `.flags`, `.args`, `.xfail` or `.repl` companions
  (`tests/README.md`). An `.xfail` that passes is an XPASS and fails the run.
- **Diagnostics are symbolic, not numbered:** `(phase-error 'no-instance-for-context ...)`.
  There is no numeric range to collide with.
- **ID schemes already in use:** `M1`–`M11` (milestones in
  `doc/REVIVAL-PLAN.md`), `BUG-1`–`BUG-9`, `LG-*` and `RT-*`
  (`doc/STRATEGY.md`), and the numbered items of `doc/plans/ROADMAP.md`. This
  harness uses `YHS-N.n` and `GATE-N`, which collide with none of them.
- **Versioning:** `*haskell-compiler-version*` in `src/compiler/top/globals.mumble`
  and `:version` in `yale-haskell.asd` change together, with a `CHANGELOG.md`
  entry. Do not bump the version in a ticket unless the ticket says so.
- **Generated artifacts:** `build/` (all build output), the unit cache
  (`~/.cache/yale-haskell/` or `$YALE_HASKELL_CACHE_DIR`), and `tools/gen/*`
  outputs (`errno-darwin.lisp`, imported libraries). Regenerate them with their
  script; never hand-edit.
- **Upstream or vendored; do not edit:**
  - `ref/` (untracked clones);
  - `tools/microcabal/MicroCabal` (submodule);
  - `tests/liquid/fq/` and `tests/liquid/lh/` (BSD, pinned upstream commits);
  - code imported from Hugs or the Reports (keep its notices).
- **Historical; read-only:** `doc/history/`, `doc/announcement`,
  `doc/REVIVAL-PLAN.md` §1–9 and the 1994 manuals under `doc/`.
- **Tools on PATH:** sbcl, ocicl, ecl, abcl, java, z3, python3, ghc, cabal,
  make, git, gh, rlwrap, gs, pdftotext, shellcheck. **Missing:** mallet,
  sblint.
- **Git:**
  - 680 commits on `ng`, which tracks `origin/ng`; `origin` also has `master`.
  - No nested `.git` directories.
  - `tools/microcabal/MicroCabal` is a submodule
    (`https://github.com/echawk/MicroCabal.git`, branch `yale-backend`, pinned
    at 60337f9, which is the branch tip as of 2026-11-12). It is **not
    initialised** in this checkout. `tools/microcabal/mcabal` initialises it on
    first use.
  - `.gitignore` already ignores `/.claude/*` except `/.claude/skills/`.

## 4. Architecture

```text
 .hs / .hu ──▶ parser ──▶ import-export ──▶ tdecl/derived ──▶ prec/scope ──▶ depend ──▶ type
                                                                                       │
                ┌──────────────────────────────────────────────────────────────────────┘
                ▼
               cfn ──▶ [typed core: retype, census → lint (YHS-1.3)]
                │
                ▼
              FLIC ──▶ optimize (inline, specialize, foldr/build, case-of-case)
                │          ▲ --optimizers / -O
                ▼
     strictness + box ──▶ GRIN lower ──▶ GRIN opt (-g) ──▶ GRIN emit ──▶ Lisp ──▶ SBCL native
                │                                                      ▲
                └──────────── --backend flic (old back end) ───────────┘
 code quality: *code-quality* 2/3 = safety 0 (default); 0/1 = safety 3/1 (safe mode, YHS-1.1)

 Oracles around the pipeline:
   GHC 9.14.1 ── extensions.py · nofib.py · ghc_testsuite.py · real-world runners · fuzzer (YHS-2.4)
   self      ── metamorphic.py (YHS-1.4): optimizers on/off, grin/flic, -g none/all
   host      ── safe mode (YHS-1.1/1.2) · SBCL/ECL/ABCL agreement at gates
```

### 4.1 Recommended libraries / tools

| Concern | Choice | Why |
|---|---|---|
| Host Lisp | SBCL 2.6.x (2.6.10 verified locally) | Main host; the saved image is the executable. |
| Lisp dependencies | ocicl 2.20.0 with `ocicl.csv` (sha256-pinned) | Already used. Reproducible, and `ocicl lint` is built in. |
| Reference compiler | GHC 9.14.1 | All expected outputs and differential oracles come from it. |
| SMT | Z3 (5.3.3 verified locally) | Used by `src/liquid/`. Every query needs a timeout (YHS-0.2). |
| Lisp lint | `ocicl lint` (in ocicl 2.20.0) and Mallet v0.9.1 (MIT, prebuilt binaries; https://github.com/fukamachi/mallet) | Ratchet counters only. Neither reads `.mumble`. Mallet's behaviour on mumble macros is **verify in YHS-0.4**. |
| Shell lint | shellcheck | `tests/run-tests`, `bench/*`, `tools/**/*.sh` and `scripts/check.sh`. |
| Coverage | sb-cover (SBCL contrib) | Coverage floor for the compiler over `make test`. Whether it works on mumble-generated code is **verify in YHS-1.5**. |
| Timeouts | `tools/bound SECONDS CMD...` | `perl alarm` does not stop yale-haskell; `bound` kills the process group. |
| Program generator | Haskell plus QuickCheck under GHC, or Python, whichever YHS-2.4's spike picks | Technique from Pałka, Claessen, Russo and Hughes, "Testing an Optimising Compiler by Generating Random Lambda Terms", AST 2011. |

### 4.2 Repository layout

New paths are marked `(new)`.

```text
AGENTS.md                     (new) rules for every agent session
CLAUDE.md                     (new) "@AGENTS.md"
claude-prompt.md              mission brief; §6 moved to AGENTS.md, §7 superseded
doc/harness/                  (new) roadmap.md, TICKETS.md, agent-protocol.md
doc/plans/                    design references (ROADMAP.md order table superseded)
doc/STRATEGY.md               per-feature file map and invariants (reference)
notes/                        (new) handoff, review and gate notes; evidence
  templates/                  (new) handoff.md, review.md, gate.md
.claude/skills/               (new) start-ticket, finish-ticket, review-ticket,
                              milestone-gate, yale-dev,
                              correctness, perf-change, conformance-target
scripts/check.sh              (YHS-0.3) the single gate command; CI calls it
scripts/ratchet-baseline.txt  (YHS-0.4) recorded counts; only ever lowered
doc/harness/baselines.md      (YHS-0.8) conformance and host counts with dates
tools/conformance/metamorphic.py  (YHS-1.4)
tools/conformance/agda.py     (YHS-2.1)
tools/fuzz/                   (YHS-2.4) program generator and runner
src/ tests/ lib/ tools/ bench/   unchanged layout (README.md §Layout)
```

`notes/` sits at the top level rather than under `doc/harness/` for three
reasons. Notes are working records and evidence (logs, benchmark output), not
user-facing documentation. Top-level keeps their paths short in every skill.
And it keeps large evidence files out of `doc/`.

## 5. Domain model / core data structures

The hub entity is the **compilation unit** (`.hu` file, or the implicit unit of
a `.hs`). It is compiled through the pipeline into a cached interface (`.hi`
data) plus compiled Lisp (fasl), keyed by sources, flags and the compiler
version (`src/compiler/csys/unit-cache.mumble`).

| Structure | Where | Notes |
|---|---|---|
| AST | `src/compiler/ast/` | Front-end trees; walkers in `util/walk-ast.mumble`. |
| FLIC | `src/compiler/flic/` | Intermediate language after cfn; optimizer and strictness work here. |
| Typed core | `src/compiler/typed/` | Retypes cfn output; a census tool exists (`tools/typed-core.py`). |
| GRIN | `src/compiler/grin/` | Eval/apply back end with explicit laziness (`doc/EVAL-APPLY-GRIN.md`). |
| Dictionaries | `src/compiler/type/dictionary.mumble`, runtime tuples | Layout comes from class definitions (`dict-super-slot`, `class-n-methods`). |
| Feature table | `src/compiler/top/globals.mumble` | `*dialect-features*`; all dialect gating. |

**Invariants**

- Output of every program equals GHC 9.14.1's (or the Report's) output. Expected
  files are never produced by copying Yale's own output.
- `make test` stays green on SBCL after every ticket, for both dialects. The
  Haskell 1.2 demos are a fixed regression baseline.
- Dialect differences go through `feature?`; no raw `(haskell98?)` in new code.
- Host-specific calls stay behind `#+` in `src/mumble/` or `src/runtime/`.
- Generated Lisp keeps readable `|Module:name|` names; `*code-quality*` applies
  to program code as to the prelude.
- Interface files round-trip: type, kind and name representation changes update
  `backend/interface-codegen.mumble`, `backend/dump-interface.mumble` and
  `import-export/interface-parser.mumble` together.
- Every optimizer pass can be switched off by name; on and off agree on output.
- No nhc98 code and no copyleft code; Hugs and Report code keep their notices.

## 6. External integrations: facts and pain points

### 6.1 GitHub Actions (CI)
- **Facts:** `.github/workflows/ci.yml` runs on `ubuntu-latest` and
  `macos-latest`. It installs SBCL with apt or brew, then runs `make` and
  `make test`. It never runs `ocicl install` or initialises the submodule. The
  last 40 runs failed (2026-11-12). Ubuntu 24.04's apt SBCL is 2.2.9
  (Launchpad, `sbcl 2:2.2.9-1ubuntu2`); README says tested with 2.6.
- **Pain points:**
  - Pinning SBCL 2.6.x on Linux needs a binary tarball or a source build. The
    exact method is **verify in YHS-0.1**.
  - The test suite takes about 5 minutes locally, and the job timeout is 60
    minutes.
  - `ocicl` itself must be installed on the runners. The method is **verify in
    YHS-0.1**.

### 6.2 ocicl registry (ghcr.io/ocicl)
- **Facts:** `make deps` runs `ocicl install`, which fetched every system in
  `ocicl.csv` by sha256 digest in 3.9 s (2026-11-12).
- **Pain point:** network access is needed on a fresh clone. CI caches
  `ocicl/`, keyed on the hash of `ocicl.csv`.

### 6.3 Z3
- **Facts:** `src/liquid/z3.lisp` drives `z3 -smt2 -in`.
- **Pain point:** at least one query in `make liquid-test` runs for more than 9
  minutes. YHS-0.2 adds a per-query timeout (Z3's `-T:` or `(set-option :timeout
  N)`; which one works over the pipe is **verify in YHS-0.2**).

### 6.4 Hackage via MicroCabal
- **Facts:** `tools/microcabal/mcabal` runs MicroCabal from the submodule, with
  Yale as backend. It installs into `$CABALDIR` (default `~/.mcabal`) and
  fetches packages with curl and tar.
- **Pain points:**
  - Network access is needed.
  - The default install directory is outside the repository; tickets set
    `CABALDIR` to a scratch directory or under `build/`.
  - Packages that need GHC-only features are patched in
    `tools/microcabal/patches/`.

### 6.5 GHC testsuite and reference clones
- **Facts:** `ref/ghc-testsuite` is a sparse clone of GHC at
  `ghc-9.14.1-release` (902339d), following the recipe in `ref/README.md`.
  `tools/conformance/ghc_testsuite.py` reads `all.T` files without running them
  and runs single-module `compile_and_run` tests.
- **Pain point:** `ref/` is gitignored, so a clean clone has none of it. Gate
  runs recreate it with `make ref` or the README recipe.

## 7. Core algorithms

### 7.1 Metamorphic runner (YHS-1.4)
- **Inputs:** test programs (`tests/haskell98/**.hs` with their `.flags`,
  `.stdin` and `.args`) and a list of configurations:
  - `default`;
  - `-O` (FLIC optimizer off);
  - `--backend flic`;
  - `-g none`;
  - optionally `--optimizers` subsets.
- **Output:** for each program, whether every configuration's exit status and
  stdout equal the expected `.stdout`/`.exit`. Mismatches are written to
  `build/conformance/metamorphic/results.tsv`.
- **v1:** exhaustive over the configurations, `-j N`, per-run `tools/bound`
  timeout. Cost is O(programs × configurations).
- **Stretch:** delta-debug which pass, by name, causes a mismatch.

### 7.2 Random program fuzzer (YHS-2.4 to YHS-2.6)
- **v1:** generate well-typed, terminating Haskell 2010 programs from a seed.
  Use first-order and higher-order functions over `Int`, `Integer`, `Bool`,
  lists, tuples, `Maybe` and small user ADTs. Keep `Int` arithmetic within ±2^62
  so the 63-bit `Int` does not differ from GHC's. Programs print their results
  with `show`.
- **Oracle:** GHC `-O0` output against Yale's output in every metamorphic
  configuration.
- **Required properties:**
  - the same seed gives byte-identical programs;
  - every generated program compiles under GHC;
  - a discrepancy is saved with its seed, configuration and both outputs.
- **Stretch:** type-class-heavy programs (dictionaries, specialization), laziness
  (`undefined` in unforced positions), and an automatic reducer.
- **Pain points:**
  - Generating well-typed programs is subtle (Pałka et al.).
  - Non-termination and `Int` overflow must be excluded by construction, not
    filtered after.

## 7b. Correctness strategy

The ladder runs from proof, through refinement types, property tests and fuzzing,
then static analysis, then unit tests. For this stack (a mumble/Common Lisp
compiler plus Haskell libraries):
- **Formal methods:** no practical proof tooling applies to the compiler itself.
  `src/liquid/` checks Haskell programs and may later check `lib/` (not in
  scope).
- **Mutation testing:** no maintained Common Lisp mutation tool was found
  (2026-11-12).
- **The top affordable rungs** are therefore differential and metamorphic
  testing, random-program fuzzing, a typed IR lint, and safe-mode runs, with
  ratchets on everything below them.

| Module / area | Rung | Tools | Evidence required per ticket |
|---|---|---|---|
| Optimizer and back ends (`src/compiler/backend/`, `flic/`, `grin/`) | Fuzzing + metamorphic + typed IR lint + safe mode | `metamorphic.py`, fuzzer, `YALE_HASKELL_LINT`, safe mode (after M1/M2) | A new or changed pass: a regression test; metamorphic agreement with the pass on and off; a fuzzer run of ≥ 1,000 programs (after YHS-2.6) with no new discrepancy; typed-core lint count not raised. |
| Type checker (`src/compiler/type/`, `typed/`, `tdecl/`, `derived/`) | Differential against GHC + typed-core agreement | `extensions.py`, `ghc_testsuite.py`, `tools/typed-core.py` | Positive and negative (`.exit 1`) tests; extension-probe count not lowered; typed-core disagreements not raised. |
| Runtime and base (`src/runtime/`, `src/base/`, `src/ffi/`) | Safe-mode run + differential | safe mode, `make test` | Tests pass in normal and safe mode (after YHS-1.2). FFI changes keep the SBCL-only ones behind `#+sbcl`. |
| Haskell libraries (`lib/haskell98/`) | Differential + properties | GHC outputs, QuickCheck under Yale and GHC | Expected output generated by GHC; laws as QuickCheck properties where the library has laws (Monoid, Functor, Ord). |
| Front end (`parser/`, `import-export/`, `prec/`, `depend/`) | Unit-style programs + GHC testsuite | `make test`, `ghc_testsuite.py` | Test per feature; GHC-testsuite PASS count not lowered. |
| Liquid (`src/liquid/`) | Unit tests + vendored pos/neg corpus | `make liquid-test` | Counts not lowered; every solver call has a timeout. |
| Lisp infrastructure (`src/mumble/`, `tools/build/`, `src/cli/`) | Static analysis ratchet | SBCL warnings, `ocicl lint`, Mallet | Ratchet counts not raised. |
| Scripts (`*.sh`, `tests/run-tests`, `bench/*`) | Static analysis | shellcheck | shellcheck clean for new or changed scripts. |

**Commands:**
- `scripts/check.sh` runs the full gate (from YHS-0.3).
- `scripts/check.sh --ratchet` runs only the counters (from YHS-0.4).
- `tools/conformance/metamorphic.py` (from YHS-1.4).
- `tools/fuzz/run --seed S --count N` (from YHS-2.4; exact interface fixed by
  that ticket).
- `YALE_HASKELL_LINT=1 tests/run-tests` (from YHS-1.3).
- `make SAFE=1` and `make SAFE=1 test` (from YHS-1.2; the exact name is fixed
  by that ticket).

**Ratchet.** `scripts/ratchet-baseline.txt` holds the counts. `check.sh` fails
when any count rises. Lowering a count means editing the baseline in the same
ticket, as a recorded improvement. The counted items are:
- SBCL WARNING and STYLE-WARNING counts per build log;
- `ocicl lint` findings per directory;
- Mallet findings;
- `.xfail` files;
- typed-core disagreements;
- metamorphic mismatches;
- the sb-cover coverage percentage (a floor, which may only rise).

Suppressions (`declare (sb-ext:muffle-conditions ...)`, lint ignores, new
`.xfail`) need a comment with a justification and a ticket ID, plus reviewer
approval recorded in the review note. Tools not yet tried are marked
**verify in <ticket>** above.

## 8. Milestones and tickets

Tickets are sized for one builder session. Each milestone ends at a reviewer gate.
Unless a ticket says otherwise, its test is its named command plus
`make test` (and `scripts/check.sh` once YHS-0.3 is done). Long runs go through
`tools/bound`.

Every gate, in addition to its demo, requires the evidence chosen on 2026-11-12:
- `make test` counts for both dialects, plus embed and liquid counts;
- the conformance runner counts touched by the milestone, compared with
  `doc/harness/baselines.md`;
- `bench/compare-ghc -n 3` tables for performance milestones;
- ECL and ABCL counts compared with YHS-0.7's;
- **the human's push of `ng` with all of the milestone's merges, and a green CI
  run on Ubuntu and macOS** (run URL in the gate note).

### Milestone 0: Baseline and hygiene

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-0.1 | Fix CI | (1) The failure cause is identified from the logs of the existing failed runs (`gh run view <id> --log-failed`, read-only) and written in the handoff note, settling the "verify" in §3 and §6.1. (2) `ci.yml` installs SBCL 2.6.x pinned to an exact version on both runners, installs ocicl, runs `ocicl install`, caches `ocicl/` keyed on `hashFiles('ocicl.csv')`, checks out with submodules, and prints the SBCL version. (3) Every shell step of the workflow is run locally in order on a clean clone and passes (commands in the handoff note). (4) CI going green is confirmed when the human next pushes `ng`; the result is recorded at GATE-0. Builders never push. | the workflow's steps, run locally on a clean clone |
| YHS-0.2 | Z3 query timeout in yale-liquid | (1) The hanging query is identified (test name in the handoff note). (2) Every Z3 query has a timeout (default 10 s, `$YALE_LIQUID_Z3_TIMEOUT` overrides). A timed-out query is reported as `unknown`, naming the query, and never hangs. (3) `make liquid-test` finishes in under 5 minutes locally with counts no lower than the baseline in §3. (4) A unit test covers the timeout path. | `tools/bound 600 make liquid-test` |
| YHS-0.3 | `scripts/check.sh` | (1) One script runs `make`, `make test`, `make haskell-1.2`, `tests/run-tests tests/haskell-1.2`, `make embed-test` and `make liquid-test`, plus shellcheck on repository shell scripts. (2) Liquid tests skip with a message when z3 is missing. (3) Exit status is non-zero on any failure, and a summary line per stage is printed. (4) `--quick` runs only `tests/haskell98/smoke` and the ratchet. (5) CI calls `scripts/check.sh`. (6) It is shellcheck clean. | `scripts/check.sh; echo $?` |
| YHS-0.4 | Ratchet counters | (1) `scripts/ratchet-baseline.txt` records the SBCL WARNING/STYLE-WARNING counts per build log, `ocicl lint` findings per top-level source directory (`.lisp` only), Mallet findings (Mallet v0.9.1 pinned, or a recorded reason it cannot run: **verify** mumble macro handling), and the `.xfail` count. (2) `scripts/check.sh --ratchet` fails when any count rises and prints which. (3) A deliberate extra warning on a scratch branch makes it fail (evidence in `notes/YHS-0.4/`). | `scripts/check.sh --ratchet` |
| YHS-0.5 | Submodule in setup docs and tests | (1) README "Building" and `doc/GUIDE.md` include `git submodule update --init`. (2) Every test or runner that needs MicroCabal skips with a message naming the command when `tools/microcabal/MicroCabal/src` is absent. (3) The list of such tests and runners is in the handoff note. | `scripts/check.sh` on a checkout without the submodule |
| YHS-0.6 | Stale facts | (1) `tools/conformance/extensions.py` is re-run. (2) README "What to expect" states the current probe count with its date (README says 101/104; `doc/plans/ROADMAP.md` says 139/140). (3) Other count claims in README are checked against `doc/plans/*` and corrected, or marked with a date. | `tools/bound 3600 tools/conformance/extensions.py` |
| YHS-0.7 | ECL and ABCL baselines | (1) `make LISP=ecl`, `make LISP=abcl` and their test runs are done on the current suite. (2) Pass counts with date and versions go into `doc/plans/PORTABILITY.md`'s status table and `doc/harness/baselines.md`. (3) New failures since 2026-10-16 are listed (not fixed). | `make LISP=ecl && YALE_HASKELL_LISP=ecl tests/run-tests -j 8` (same for abcl) |
| YHS-0.8 | Conformance baselines | (1) `doc/harness/baselines.md` records dated counts for `make test` (both dialects), embed, liquid, `extensions.py`, `nofib.py --try-all`, `ghc_testsuite.py` (with `ref/ghc-testsuite` created by the `ref/README.md` recipe) and each real-world runner touched by later milestones. (2) Each row gives the exact command and wall time. (3) Gates compare against this table. | the commands in the table |
| YHS-0.9 | Hermetic build check | (1) Determine whether `make` reuses compiled files from outside the repository, such as an ASDF output-translation cache (the "verify" in §3). (2) If yes, make the build write only under `build/` (or document the exact cache and how to clear it) so that a clean-clone gate is meaningful. (3) Measure clean `make` time after `make clean` with any external cache cleared. | `make clean && make` with timings in the handoff note |
| GATE-0 | Milestone 0 gate | see below | |

**Gate 0 demo:** a fresh `git clone --recurse-submodules` of `ng` in a scratch
directory, then `ocicl install` and `scripts/check.sh`, is green. After the
human pushes `ng`, CI is green on Ubuntu and macOS; the run URL goes in the gate
note. A scratch commit that adds a compile warning makes
`scripts/check.sh --ratchet` fail. `doc/harness/baselines.md` exists with dated
counts, ECL and ABCL included.

**Pain point:** CI can only be observed after the human pushes `ng`, so a CI fix
may need more than one push. Builders and reviewers never push; if CI fails
after the push, the reviewer opens a follow-up ticket (YHS-0.1a) from the run's
log.

### Milestone 1: Correctness infrastructure

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-1.1 | Safe mode for program and library units | (1) `YALE_HASKELL_SAFETY=1` or `=3` compiles program and library units with code quality 1 (`safety 1`) or 0 (`safety 3`), using the existing `code-quality-declaration-1` in `src/mumble/cl-definitions.lisp`. (2) The unit cache key includes the safety level, so safe and fast units never mix (a test proves it: compile fast, then safe, and check the safe fasl was rebuilt). (3) The default is unchanged. (4) A test program whose bug is a type error under safety 3 is reported, not a crash. | `YALE_HASKELL_SAFETY=3 tests/run-tests tests/haskell98/smoke tests/haskell98/prelude` |
| YHS-1.2 | Safe prelude image and full safe run | (1) `make SAFE=1` builds a safe image under `build/sbcl-safe/` (or a name chosen and documented here) with the prelude and libraries at safety 3. (2) `make SAFE=1 test` runs the whole suite. (3) Every failure is listed in `notes/YHS-1.2/findings.md` with its first error. Each real miscompilation becomes a new ticket row (YHS-1.2a, 1.2b ...) or an `.xfail` naming that ticket. (4) The default build is unchanged. | `tools/bound 7200 make SAFE=1 test` |
| YHS-1.3 | Typed-core lint | (1) `YALE_HASKELL_LINT=1` runs the typed phase after cfn and stops compilation with a structured message on any typing failure or disagreement, naming the binding. (2) Spike result in the handoff note: whether the typed core can also retype FLIC after optimize (**verify**). If yes, lint there too; if no, a follow-up ticket row. (3) The disagreement count over `tests/haskell98` is recorded in the ratchet baseline. | `YALE_HASKELL_LINT=1 tests/run-tests tests/haskell98/language` |
| YHS-1.4 | Metamorphic runner | (1) `tools/conformance/metamorphic.py [-j N] [PATH...]` implements §7.1. (2) It writes `build/conformance/metamorphic/results.tsv`. (3) A full run's mismatch list is recorded (`notes/YHS-1.4/`) and its count is added to the ratchet. (4) `scripts/check.sh` runs it time-boxed on `tests/haskell98/smoke` and `tests/haskell98/language`. (5) A unit test of its comparison logic covers an exit-code mismatch and a stdout mismatch. | `tools/conformance/metamorphic.py -j 8 tests/haskell98/language` |
| YHS-1.5 | Coverage floor with sb-cover | (1) `make coverage` builds the compiler with `sb-cover:store-coverage-data`, runs `make test` and writes an HTML report under `build/coverage/`, plus a single expression-coverage percentage on stdout. (2) The percentage is recorded as a floor in the ratchet baseline. (3) Whether sb-cover instruments mumble-generated code is answered (**verify**); if not, coverage is reported for `.lisp` sources only and the gap is recorded. | `tools/bound 7200 make coverage` |
| YHS-1.6 | Wire correctness tools into check and CI | (1) `scripts/check.sh --full` adds the safe run, lint and full metamorphic runs. (2) The default `check.sh` keeps a wall time under 15 minutes locally (measured). (3) CI runs the default on push and `--full` on a weekly schedule (`workflow_dispatch` too). (4) The `correctness` skill is updated with the real commands. | `scripts/check.sh --full` |
| GATE-1 | Milestone 1 gate | see below | |

**Gate 1 demo:**
1. On a scratch branch, introduce a lying type declaration in one runtime
   primitive. The default build gives wrong output or a crash; the safe build
   reports a type error that names the function.
2. Show the metamorphic results table for `tests/haskell98`.
3. Show the typed-core lint count and the coverage percentage.
4. Run ECL and ABCL against the YHS-0.7 counts.

### Milestone 2: Miscompilations (Agda faults and the fuzzer)

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-2.1 | Reproducible Agda build and Succeed run | (1) `tools/conformance/agda.py` builds Agda 2.8.0.2 with `tools/microcabal/mcabal` (with `CABALDIR` under `build/`) and runs its Succeed suite, writing PASS/FAIL per file and a count. (2) The count is recorded in `doc/harness/baselines.md` (compare 1183/1852 of 2026-10-27). (3) Memory-fault failures are listed separately. | `tools/bound 28800 tools/conformance/agda.py` |
| YHS-2.2 | Agda faults under safe mode | (1) The faulting Succeed files are re-run with Agda built in safe mode (YHS-1.1/1.2). (2) The first error of each fault is recorded with the Haskell binding and module it comes from (`Eq NotBlocked'` and `compactDef` are known suspects, `doc/plans/ROADMAP.md`). | `YALE_HASKELL_SAFETY=3 tools/conformance/agda.py --only <files>` |
| YHS-2.3 | Minimise and fix the first Agda miscompilation | (1) A standalone program of 150 lines or fewer reproduces the fault and is added as a test whose expected output comes from GHC. (2) The compiler is fixed; the test passes in default and safe mode and in every metamorphic configuration. (3) The Agda Succeed count is re-measured and does not drop. Further distinct faults become rows YHS-2.3a, 2.3b ... | the new test; `tools/conformance/agda.py` |
| YHS-2.4 | Random program generator v1 | (1) A spike decides between Haskell+QuickCheck under GHC and Python (whether QuickCheck is installed for GHC 9.14.1 is **verify**). (2) `tools/fuzz/` implements the §7.2 v1 generator. (3) The same seed gives byte-identical programs (test). (4) 100 of 100 sampled programs compile under GHC. (5) The README in `tools/fuzz/` gives the commands. | `tools/fuzz/run --seed 1 --count 100` |
| YHS-2.5 | Fuzz runner, oracle and reducer | (1) The runner compiles each program under GHC `-O0` and Yale in every metamorphic configuration. (2) It saves discrepancies under `build/fuzz/<seed>/` with outputs and configuration. (3) A greedy reducer shrinks a discrepancy while it persists. (4) 1,000 programs run with a report. (5) Each discrepancy found gets a ticket row or a reduced `.xfail` test naming one. | `tools/fuzz/run --seed 1 --count 1000` |
| YHS-2.6 | Fuzzer in CI | (1) A time-boxed fuzz run (5 minutes, new seed each run, seed printed) is part of `scripts/check.sh --full` and the weekly CI job. (2) A failure output includes the reproduction command. | `scripts/check.sh --full` |
| GATE-2 | Milestone 2 gate | see below | |

**Gate 2 demo:**
1. Run `tools/conformance/agda.py`. The Succeed count is reported against
   1183/1852, and the first memory fault's reduced test passes.
2. Run `tools/fuzz/run --count 10000` from a fresh seed. It finishes with zero
   unexplained discrepancies; every discrepancy has a ticket.
3. Run ECL and ABCL against their recorded counts.

### Milestone 3: Conformance number and compile time (Track K)

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-3.1 | GHC-testsuite baseline and categories | (1) A full `ghc_testsuite.py` run over `DEFAULT_DIRS` records PASS/WRONG/EXIT/COMPILE/RUNTIME/TIMEOUT/SKIP counts in `doc/harness/baselines.md`. (2) Two consecutive runs agree except for a listed set of flaky tests. (3) SKIP reasons are categorised in `results.tsv`. | `tools/bound 28800 tools/conformance/ghc_testsuite.py` |
| YHS-3.2 | Triage failures | (1) A ranked list of failure causes (cause, count, example test, likely file) goes into `doc/plans/CONFORMANCE.md`, under a dated section. (2) The top 4 causes become ticket rows YHS-3.3 to 3.4 (renamed) or new rows 3.4a ... | report only |
| YHS-3.3 | Fix failure cause #1 from YHS-3.2 | The PASS count rises by the cause's count (or the shortfall is explained). No other count falls. A regression test is added under `tests/haskell98/`. | `ghc_testsuite.py` on the affected dirs |
| YHS-3.4 | Fix failure cause #2 from YHS-3.2 | Same acceptance as YHS-3.3. | as YHS-3.3 |
| YHS-3.5 | Fixpoint round counters | Import-export's and derived-instances' fixpoints and unify's deferred family equalities each count their rounds. Under `YALE_HASKELL_TRACE`, each names itself when its limit is reached, as the strictness limit already does (`doc/plans/ROADMAP.md` "Compile-time audit"). A test triggers each limit. | `tests/run-tests` on the new tests |
| YHS-3.6 | Compile-time benchmark | (1) `bench/compile-time` times compiling a fixed set: vector's modules, lens's check, aeson's first build and `tests/haskell98/lib`, with a cold unit cache. (2) A dated table is appended to `bench/RESULTS.md`. (3) The slowest 5 units are listed with phase times (`YALE_HASKELL_TIME=1`). | `bench/compile-time` |
| GATE-3 | Milestone 3 gate | see below | |

**Gate 3 demo:**
1. Show the GHC-testsuite PASS count against the YHS-3.1 baseline, with the
   increase attributed to YHS-3.3 and YHS-3.4.
2. Show the compile-time table.
3. Re-run `make test`, the extensions probe count and nofib, with no regression
   against `doc/harness/baselines.md`.
4. Run ECL and ABCL against their recorded counts.

### Milestone 4: Pandoc chain I: basement, memory, crypton (Track P)

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-4.1 | basement builds | (1) The failure is fixed: basement's `Integral Word128` is taken for the Prelude's class (`doc/plans/ROADMAP.md` "Pandoc"). The fix is in name resolution, not a patch, unless the handoff note justifies a patch. (2) `mcabal install basement` succeeds. (3) A reduced test is added. | `tools/microcabal/mcabal -r install basement` |
| YHS-4.2 | memory builds | `mcabal install memory` succeeds. A smoke program using `Data.ByteArray` matches GHC's output. | same, `memory` |
| YHS-4.3 | crypton survey | Each `crypton-*` package and `crypton` itself is built. A table (package, result, first error) goes into `doc/plans/REAL-WORLD-TARGETS.md`. Tickets 4.4/4.5 are refined from it. | report only |
| YHS-4.4 | crypton builds | `mcabal install crypton` succeeds. A program hashing a fixed string with SHA-256 and printing hex matches GHC's output. | the smoke program |
| YHS-4.5 | tls and http-client-tls build | Both install. A program that constructs (does not connect) a TLS client config compiles and runs. | `mcabal -r install http-client-tls` |
| GATE-4 | Milestone 4 gate | see below | |

**Gate 4 demo:** from a scratch `CABALDIR`, `mcabal -r install
http-client-tls` succeeds. The crypton SHA-256 program's output equals GHC's.
`make test` and the conformance counts show no regression. ECL and ABCL are run
against their recorded counts.

### Milestone 5: Pandoc chain II and user programs

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-5.1 | Pandoc closure status | A dated table of pandoc 3.11's dependency closure (package, built yes/no, blocker) goes in `doc/plans/REAL-WORLD-TARGETS.md`, refreshed from `doc/plans/ROADMAP.md` "Pandoc". | report only |
| YHS-5.2 | Template Haskell packages | file-embed and th-lift build, through `src/compiler/th/` (north-star hook). Each has a smoke program matching GHC. | `mcabal install file-embed th-lift` |
| YHS-5.3 | C-library packages | zlib-clib and libyaml-clib build, or a documented decision to link system libraries. Each has a smoke program. | `mcabal install ...` |
| YHS-5.4 | commonmark and texmath | Both build. Their own test suites run, with a pass count recorded. | `mcabal test commonmark` (exact command **verify**) |
| YHS-5.5 | User-program batch harness | (1) `tools/conformance/userprogs.py` runs a corpus of at least 100 user programs against GHC output. The corpus is from sources whose licences allow copying (**verify** per source; a provenance file lists source, licence and date). (2) The pass count is recorded in `doc/harness/baselines.md`. | `tools/conformance/userprogs.py` |
| YHS-5.6 | Fix top user-program failure causes | The top 2 causes from 5.5 are fixed, each with a regression test. The pass count rises. | `userprogs.py` |
| GATE-5 | Milestone 5 gate | see below | |

**Gate 5 demo:** show the pandoc closure table with its built count against
YHS-5.1's first count. Re-run the user-program pass count against YHS-5.5's
baseline. Run the conformance counts and ECL/ABCL with no regression.

### Milestone 6: Runtime performance I (after GATE-5; never before GATE-2)

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-6.1 | Performance baseline | A dated `bench/RESULTS.md` section with `bench/compare-ghc -n 3`, plus allocation (Yale MB) for LambdaPi, Mini-TT and cubicaltt torsor/grothendieck, all taken in one quiet session. | `bench/compare-ghc -n 3` |
| YHS-6.2 | One-object thunks | (1) Thunks become a single object (a funcallable instance or a closure with a mutable slot) instead of cons plus closure (`claude-prompt.md` §5.1). (2) Allocation on LambdaPi, Mini-TT and torsor is reported before and after. (3) The metamorphic run and a 1,000-program fuzz run are clean. (4) Keep only with a measured gain. Split into 6.2a/6.2b if it exceeds a session. | `bench/compare-ghc -n 3`; fuzz |
| YHS-6.3 | Demand analysis: absence | Unused arguments are dropped in `/OPT` workers (`backend/strictness.mumble`). Before/after numbers are reported. Metamorphic and fuzz runs are clean. | same |
| YHS-6.4 | Demand analysis: strict constructor fields | Strictness flows into constructor fields (strict `Int` in a tuple) and through transformer-stack `>>=`. Numbers are reported; metamorphic and fuzz runs are clean. | same |
| GATE-6 | Milestone 6 gate | see below | |

**Gate 6 demo:** a `bench/compare-ghc -n 3` table shows the modern bench
programs (foldable, mapcount, statemonad, starray) and LambdaPi/Mini-TT moving
toward 2× GHC -O2, against YHS-6.1. The fuzzer runs 10,000 programs clean.
`make test`, the conformance counts and ECL/ABCL show no regression.

### Milestone 7: Runtime performance II

| ID | Title | Deliverable / acceptance | Test |
|---|---|---|---|
| YHS-7.1 | CPR and worker/wrapper with `values` | Functions that always return a known constructor return its fields unboxed through CL `values` (`doc/EVAL-APPLY-GRIN.md` §5.4 items 3–4). statemonad's allocation (418 MB) is reported before and after. Metamorphic and fuzz runs are clean. | `bench/compare-ghc -n 3` |
| YHS-7.2 | Case-of-case with join points | The 60-node limit of `let-case-of-case` is replaced by join points (`claude-prompt.md` §5.4). Before/after numbers are reported; metamorphic and fuzz runs are clean. | same |
| YHS-7.3 | Performance write-up | README "What to expect" and `doc/plans/GHC-OPTIMIZATIONS.md` status cells are updated from a fresh `compare-ghc -n 3` run. | `bench/compare-ghc -n 3` |
| GATE-7 | Milestone 7 gate | see below | |

**Gate 7 demo:** a fresh `compare-ghc -n 3` table shows the geometric-mean
ratio against YHS-6.1, with statemonad's allocation reported. The fuzzer runs
10,000 programs clean. All counts in `doc/harness/baselines.md` hold, and
ECL/ABCL are run.

## 9. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| CI cannot pin SBCL 2.6.x cheaply on Linux | Medium | Medium | YHS-0.1 tries a pinned binary release first, then a cached source build. macOS-only CI as a last resort needs a human decision. |
| Safe mode changes behaviour (it is not only a checker) | Medium | High | YHS-1.1 keeps the default unchanged and caches by safety level. Findings are triaged, never "fixed" by turning safety off. |
| Agda faults are several distinct bugs | High | Medium | YHS-2.3 fixes the first; the others get `a`/`b` rows. The gate demo requires only the first plus no count drop. |
| The fuzzer finds many discrepancies that swamp the tracks | Medium | Medium | Each becomes a reduced `.xfail` test with a ticket. The xfail ratchet keeps them visible. Performance work waits for GATE-2. |
| Performance changes introduce miscompilations | High | High | M6 never starts before GATE-2. Each performance ticket needs metamorphic and fuzz evidence. Reviewers re-run them. |
| Pandoc's chain hits Template Haskell or C-library walls | High | Medium | Track P is independent; it can stop at a documented blocker without delaying Track K. |
| Long runs (Agda, GHC testsuite, ECL) exhaust a builder session | High | Low | Run through `tools/bound`, save logs in `notes/<ID>/`, record wall times in `baselines.md`. |
| CI breakage is seen late, because only the human's pushes of `ng` run CI | Medium | Medium | `scripts/check.sh` mirrors the CI steps locally. Every gate includes the human's push and the CI result. |

## 10. Open decisions (human)

1. How should CI pin SBCL 2.6.x on Linux? A binary tarball, a source build or a
   third-party action. YHS-0.1 proposes; the human approves the method.
2. Licensing of the user-program corpus for YHS-5.5. Which sources (Rosetta
   Code, Advent of Code solutions, textbook code) are acceptable to vendor?
3. Should ECL/ABCL gate failures block a gate, or only be recorded as
   regressions with a follow-up ticket?

## 11. Context for agents

- Read `AGENTS.md` first. Then read this file's North-star section, §3 and your
  ticket's milestone.
- The design references are `doc/STRATEGY.md`, `doc/plans/*.md`,
  `doc/EVAL-APPLY-GRIN.md` and `bench/RESULTS.md`. If a document and the source
  disagree, believe the source, and say so in the handoff note.
- "Verify" facts are owned by the ticket named next to them. That ticket checks
  the fact first and records the answer here (reviewer) or in its handoff note
  (builder).
- Expected outputs come from GHC 9.14.1 or the Report, never from Yale.
- Long commands go through `tools/bound`. Keep logs in `notes/<ID>/`.
- Set `YALE_HASKELL_CACHE_DIR` to a scratch directory when you need an isolated
  unit cache, and set `CABALDIR` to a scratch directory for mcabal.
- Do not edit `ref/`, the submodule, vendored test data or historical documents.
- Never push. Ticket branches stay local; the reviewer merges approved tickets
  into `ng` with `--no-ff`, and the human pushes `ng` to run CI.
