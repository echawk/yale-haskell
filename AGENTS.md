# AGENTS.md — Yale Haskell

Instructions for every coding agent working in this repository (Claude Code,
Codex, or any other). Read this file completely before starting work.

## 1. What Yale Haskell is

Yale Haskell is the 1994 Yale Haskell compiler revived on SBCL. It compiles
Haskell 98, Haskell 2010, GHC2021 and GHC2024 (most GHC extensions) and the
original Haskell 1.2 dialect to Common Lisp, which SBCL compiles to native code.
The compiler is written in *mumble*, a Scheme-flavoured macro layer over Common
Lisp (`src/mumble/README.md`; it is **not** Scheme). It also has a C FFI, a
refinement-type checker (`src/liquid/`, Z3), and builds Hackage packages through
MicroCabal (`tools/microcabal/`).

| Document | Role |
|---|---|
| [`doc/harness/roadmap.md`](doc/harness/roadmap.md) | **Plan of record:** scope, milestones, tickets, correctness strategy, risks, north star. |
| [`doc/harness/TICKETS.md`](doc/harness/TICKETS.md) | Live ticket status board. |
| [`doc/harness/agent-protocol.md`](doc/harness/agent-protocol.md) | Ticket lifecycle, reviewer checklist, gates. |
| `doc/harness/baselines.md` | Dated counts every gate compares with (created by YHS-0.8; until then, roadmap §3). |
| [`doc/STRATEGY.md`](doc/STRATEGY.md), [`doc/STRATEGY-CODE.md`](doc/STRATEGY-CODE.md) | File-level map of the compiler and its invariants. If one disagrees with the source, believe the source and say so. |
| [`doc/plans/`](doc/plans/README.md) | Design references per topic; tickets link to them. The order table in `doc/plans/ROADMAP.md` is superseded by the roadmap. |
| [`claude-prompt.md`](claude-prompt.md) | Mission brief and performance background (§5). Its §6 rules are now §4–§5 below; its §7 is superseded. |
| [`bench/RESULTS.md`](bench/RESULTS.md) | Every measured performance change, with numbers. |
| [`tests/README.md`](tests/README.md) | Test layout and conventions. |
| `doc/history/`, `doc/announcement`, `doc/REVIVAL-PLAN.md` §1–9, the 1994 manuals in `doc/` | Historical; read for context, do not edit. |

## 2. Roles

| Role | Who | Does |
|---|---|---|
| Builder | lower-tier model | Implements exactly **one ticket** at a time, on its own local branch. |
| Reviewer | higher-tier model | Reviews each ticket against its acceptance criteria, merges approved tickets into `ng`, runs milestone gates, and is the only role that edits `doc/harness/roadmap.md` or changes command-line flags and interfaces. |
| Human | Ethan | Pushes `ng` to GitHub (which runs CI), approves gates, answers "Open decisions". |

If you were not told your role, you are a **builder**.

## 3. Workflow (use the skills)

Each step has a skill in `.claude/skills/`. Agents without skill support open the
`SKILL.md` file and follow it as written.

1. **Builder: start.** `start-ticket` picks the next eligible ticket and creates
   the branch.
2. **Builder: implement.** Use the domain skills when they apply:
   - `yale-dev`: any change to the compiler, runtime, libraries or tests. It
     covers build and test commands, test-file conventions, dialect gating,
     debugging and long runs.
   - `correctness`: safe mode, typed-core lint, metamorphic runs, the fuzzer,
     ratchets and suppressions.
   - `perf-change`: any ticket that claims a speed or allocation change.
   - `conformance-target`: Hackage packages, real-world programs, `ref/`
     clones, patches and the GHC-comparison runners.
3. **Builder: finish.** `finish-ticket` runs the checks, writes the handoff note
   and marks the ticket `review`.
4. **Reviewer.** `review-ticket` verifies the work, then merges into `ng` and
   marks it `done`, or requests changes.
5. **Reviewer, at the end of a milestone.** `milestone-gate` runs the demo,
   writes the report, and asks the human to push `ng` and sign off.

## 4. Hard rules

1. **One ticket per branch:** `ticket/<ID>-<slug>`, from `ng`. Never commit
   directly to `ng`; only a reviewer merges, with `--no-ff`.
2. **Never push.** Ticket branches are local only; the human pushes `ng`.
3. **Stay inside the ticket's scope.** No drive-by refactors.
4. **`make test` stays green on SBCL after every change, for both dialects**
   (`make haskell-1.2` then `tests/run-tests tests/haskell-1.2`). The Haskell 1.2
   demos are a fixed regression baseline. Once YHS-0.3 lands, `scripts/check.sh`
   must pass too.
5. **New behaviour gets tests:** `tests/<dialect>/<area>/<name>.hs` with
   `.stdout` and/or `.exit` (and optional `.stdin`, `.flags`, `.args`,
   `.xfail`), as in `tests/README.md`. **Expected output comes from GHC 9.14.1
   or the Report, never from Yale Haskell's own output.**
6. **Measure every performance change** before and after, with
   `bench/compare-ghc -n 3` on a quiet machine, both in the same session. Add the
   conformance runners that cover the affected area. Append a dated section to
   `bench/RESULTS.md` like the existing ones. A performance change with no
   measured gain is dropped or reworked.
7. **Update the plan document** (`doc/plans/*.md`) that covers your work when a
   step lands, with what you measured.
8. **Real-world targets:** clone into `ref/` (gitignored). Record workarounds as
   patches in `tools/conformance/<target>/` or `tools/microcabal/patches/`,
   never as edits to the clone. Keep `tools/conformance/<target>.py` green.
9. **Do not edit:**
   - `ref/`;
   - the submodule `tools/microcabal/MicroCabal`;
   - vendored data in `tests/liquid/fq/` and `tests/liquid/lh/`;
   - historical documents;
   - generated files (`build/`, `tools/gen/` outputs; regenerate them with
     their script).
10. **Licence hygiene:** Hugs (BSD) and Report code may be copied with their
    notices. nhc98 is read-only. GHC 3.02 is for ideas only. No copyleft code.
11. **Long commands** (Agda, the GHC testsuite, ECL runs, liquid tests) run
    under `tools/bound SECONDS ...`. `perl alarm` does not stop yale-haskell.
12. **Stop and escalate** (handoff note with status `blocked`) when:
    - an external fact differs from the roadmap;
    - an invariant would have to break;
    - the ticket cannot pass within its scope;
    - a human decision, new network access or a new dependency is needed.

## 5. Design invariants (reviewers reject violations)

- **Keep the architecture.** Do not rewrite the compiler in another language.
  The pipeline order and phase boundaries stay as they are (`doc/STRATEGY.md`).
- **Gate on features, not dialects:** `(feature? 'name)`, with new features added
  to the table in `src/compiler/top/globals.mumble`. Never write raw
  `(haskell98?)` in new code.
- **Host-specific code** stays behind `#+sbcl` (and friends) in `src/mumble/` or
  `src/runtime/`. No bare `sb-ext:`/`sb-sys:` elsewhere. ECL and ABCL must not
  regress against their recorded counts (checked at gates).
- **Generated code stays profilable:** readable `|Module:name|` symbols, no
  gratuitous gensyms, and `*code-quality*` applied to program code as to the
  prelude.
- **Interface files round-trip:** type, kind or qualified-name representation
  changes update `backend/interface-codegen.mumble`,
  `backend/dump-interface.mumble` and `import-export/interface-parser.mumble`
  together.
- **Dictionary layout** is computed from class definitions (`dict-super-slot`,
  `class-n-methods`), never hard-coded.
- **The version** (`*haskell-compiler-version*` in `globals.mumble` and
  `:version` in `yale-haskell.asd`) changes only together, with a `CHANGELOG.md`
  entry, and only when a ticket says so.
- **Every optimizer pass can be switched off by name** (`--optimizers -name`,
  `-g -name`), and the output with it on equals the output with it off.
- **Correctness rungs** (roadmap §7b):
  - optimizer and back ends: metamorphic agreement plus a fuzz run (after
    YHS-2.6) plus typed-core lint count not raised;
  - type checker: positive and negative tests, extension-probe count not
    lowered;
  - runtime: passes in safe mode (after YHS-1.2);
  - Lisp infrastructure: ratchet counts not raised.

  Strictness only goes up. Suppressions, lint ignores and new `.xfail` files need
  a justification comment and a ticket ID.
- **Deliberate exceptions:**
  - `Int` is SBCL's 63-bit fixnum, wrapping modulo 2^63
    (`tests/haskell98/language/int-wrap*`); do not change the default.
  - `Control.Concurrent` is a one-thread approximation.

## 6. North-star goal (do not build; do not block)

Yale Haskell as a drop-in GHC replacement for real code, with evidence:
- pandoc builds and its test suite matches GHC;
- Agda's Succeed suite passes 1852 of 1852;
- GHC `should_run` parity;
- zero known miscompilations under the random-program fuzzer.

Keep these hooks intact:
- third-party patches only in `tools/microcabal/patches/` or
  `tools/conformance/<target>/`;
- no new global-module-name assumptions;
- Template Haskell through `src/compiler/th/`;
- the Agda run stays scripted;
- the unit cache is keyed by safety level;
- `results.tsv` columns stay stable;
- no hard-coded 63-bit width;
- every pass can be switched off by name;
- the typed core accepts new IR;
- fuzzer runs are seed-reproducible;
- GADT soft unification stays in `existentials.mumble`.

If a ticket's design would close off a hook, say so in the handoff note.

## 7. Stack and commands

SBCL 2.6.x hosts everything. Lisp libraries are pinned in `ocicl.csv` and
installed into `ocicl/` by ocicl. GHC 9.14.1 is the reference compiler for
expected outputs and differential runs. Z3 is used by `src/liquid/`. Python 3
runs the conformance tools.

```sh
make deps                          # ocicl install (once per clone; needs network)
make                               # compiler, Haskell 98 prelude, build/sbcl/haskell98/yale-haskell
make test                          # haskell98 suite: 925 passed on 2026-11-12 (about 5 min)
tests/run-tests -v -j 8 tests/haskell98/language   # a subset; -v shows diffs
make haskell-1.2 && tests/run-tests tests/haskell-1.2   # 20 passed on 2026-11-12
make embed-test                    # 2 passed on 2026-11-12
tools/bound 900 make liquid-test   # hangs in Z3 until YHS-0.2; needs z3
scripts/check.sh                   # the single gate (from YHS-0.3)
bin/yale-haskell prog.hs           # compile and run
bin/yale-haskell compile F.hs --emit optimize,grin,lisp   # inspect passes
bin/yale-haskell -O prog.hs        # FLIC optimizer off; --backend flic; -g none
bench/compare-ghc -n 3             # performance vs GHC (quiet machine)
tools/conformance/extensions.py    # extension probes vs GHC
make LISP=ecl && YALE_HASKELL_LISP=ecl tests/run-tests -j 8   # ECL (also abcl)
```

**Environment notes:**
- **Unit cache.** Compiled units are cached in `~/.cache/yale-haskell/`. Set
  `YALE_HASKELL_CACHE_DIR=<scratch dir>` for an isolated or cold cache, or
  `YALE_HASKELL_CACHE=0` to turn it off.
- **MicroCabal.** `tools/microcabal/mcabal` installs into `$CABALDIR` (default
  `~/.mcabal`); point it at a scratch directory. It needs the submodule
  (`git submodule update --init`; YHS-0.5) and network access.
- **Missing tools.** mallet and sblint are not installed. Tests needing a
  missing tool (z3, ghc, mallet) must skip with a message, not fail.
- **Debugging variables.** `YALE_HASKELL_TIME=1`, `YALE_HASKELL_PROFILE=1`,
  `YALE_HASKELL_TRACE`, `YALE_HASKELL_DEBUG=1`, `YALE_HASKELL_NO_SPECIALIZE`
  (`claude-prompt.md` §2).
- **Logs.** Build logs are in `build/sbcl/logs/`.

## 8. Layout

```text
src/mumble/        the mumble dialect on Common Lisp (host-specific code lives here)
src/compiler/      phases: parser, import-export, tdecl, derived, prec, depend, type,
                   cfn, typed, flic, backend (optimize, strictness, codegen), grin,
                   csys (driver, unit cache), command-interface, th, liquid, top
src/runtime/ src/base/ src/ffi/ src/cli/ src/liquid/
lib/haskell98/ lib/haskell-1.2/    Haskell libraries per dialect
tests/             test suite (tests/README.md)
tools/build/       Lisp build drivers   tools/conformance/  GHC-comparison runners
tools/microcabal/  MicroCabal backend, patches, submodule   tools/bound  timeouts
bench/             benchmarks and RESULTS.md
doc/harness/       roadmap, ticket board, agent protocol (this harness)
doc/plans/         design references
notes/             handoff, review and gate notes; evidence in notes/<ID>/
.claude/skills/    workflow and domain skills
ref/               untracked reference clones (make ref)
build/             all build output (ignored)
```

## 9. Style

- Mumble and Lisp: follow the surrounding file.
  - Lower-case, hyphenated names; `define`/`define-*` forms in `.mumble`.
  - `;;;` block comments at top level and `;;` inside code.
  - A header comment in new files saying what the file is for.
  - Mumble is not Scheme: check `src/mumble/README.md` before using a construct.
- Haskell tests: small, one feature per test, `module Main`, output through
  `print`/`putStrLn`.
- Python tools: standard library only, `argparse`, a module docstring with usage,
  like `tools/conformance/*.py`.
- Commits follow the repository's style, a plain sentence summary, prefixed with
  the ticket ID, e.g. `YHS-1.4: metamorphic runner over the test programs`.
- Comments explain *why*. No commented-out code. A TODO must reference a ticket
  ID.
