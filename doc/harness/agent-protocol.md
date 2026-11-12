# Agent protocol

How builders (lower-tier models), reviewers (higher-tier models) and the human
work together on Yale Haskell. [`AGENTS.md`](../../AGENTS.md) has the short
version, and the skills in `.claude/skills/` automate each step.

## Ticket format

Each ticket in [`roadmap.md`](roadmap.md) §8 is a contract with these fields.
When the roadmap table leaves a field out, these defaults apply:

    ID:           YHS-<milestone>.<n>
    Title:        one line
    Depends on:   see doc/harness/TICKETS.md
    Files:        the directories implied by the title and roadmap §4.2; anything
                  outside them must be justified in the handoff note
    Deliverable:  roadmap acceptance column
    Acceptance:   roadmap acceptance column, plus AGENTS.md §5 invariants
    Test:         roadmap Test column, plus `make test` (and ./scripts/check.sh
                  once YHS-0.3 is done)
    Out of scope: everything belonging to other tickets

## Lifecycle

    todo ──start-ticket──▶ in-progress ──finish-ticket──▶ review ──review-ticket──▶ done (merged into ng)
                                │                            │
                                ▼                            ▼
                             blocked ◀───────────── changes-requested ──▶ in-progress

- **Branch.** The builder works on branch `ticket/<ID>-<slug>`, created from
  `ng`. Branches stay **local**: nobody pushes them.
- **Handoff note.** The builder ends with `notes/<ID>.md` (from
  `notes/templates/handoff.md`). Evidence (logs, tables, benchmark output) goes
  in `notes/<ID>/`.
- **Review note.** The reviewer writes `notes/<ID>.review.md`.
- **Approve.** When the verdict is approve, the reviewer merges into `ng` with
  `git merge --no-ff` and sets the ticket to `done`. No separate human OK is
  needed per merge. (Human decision, 2026-11-12.)
- **Pushing.** The human pushes `ng` to GitHub, which runs CI. Agents never
  push.
- **Changes requested.** After `changes-requested`, the builder fixes every item
  on the same branch and appends "Round 2" to the handoff note. The reviewer
  appends "Round 2" to the review note.

## Reviewer checklist (per ticket)

- [ ] **Acceptance.** Every acceptance statement is met. Run the tests yourself
      on SBCL; do not trust the handoff note. Long runs go through `tools/bound`.
- [ ] **Scope.** No changes outside scope without a stated reason.
- [ ] **Expected outputs.** New tests have expected output from GHC 9.14.1 or the
      Report. Check at least one with `ghc` yourself.
- [ ] **Adversarial cases.** At least three were tried by the reviewer, for
      example:
      - a program in another dialect (`--haskell1.2`, `--ghc2021`);
      - the same program with `-O`, `--backend flic` and `-g none`;
      - empty input, deep recursion, `Int` bounds, Unicode text;
      - a cold unit cache (`YALE_HASKELL_CACHE_DIR` set to a fresh directory).
- [ ] **No leftovers.** No dead code, and no TODO without a ticket ID.
- [ ] **Interfaces.** Public names and command-line flags match the roadmap. No
      flag was renamed.
- [ ] **AGENTS.md §5 invariants hold:**
      - feature gating through `feature?`;
      - host code behind `#+`;
      - readable generated names;
      - interface-file round trip;
      - 1.2 untouched.
- [ ] **Correctness rung.** The rung in roadmap §7b is met for the touched
      modules. `scripts/check.sh --ratchet` passes. There are no new
      suppressions or `.xfail` files without a justification and a ticket ID.
- [ ] **Performance tickets.** Before and after numbers come from the same
      session in a dated `bench/RESULTS.md` section. Metamorphic and fuzz runs
      are clean.
- [ ] **North star.** North-star design hooks (roadmap, North-star table) are
      not closed off.
- [ ] **Docs and generated files.** The plan document covering the work
      (`doc/plans/*.md`) is updated. Generated files are regenerated, not edited.

## Roadmap changes

- **Who edits.** Only reviewers or the human edit `doc/harness/roadmap.md`.
- **Small factual amendments** are made in a review and recorded under "Roadmap
  amendments" in the review note.
- **Scope changes** go on a local branch `roadmap/<slug>` with the commit
  message `roadmap: ...`. The reviewer merges it into `ng` with `--no-ff`.
- **Inserted milestones** use `N.5` numbering and a `GATE-N.5` row, and the
  **Execution order** line is updated.
- **Human decisions** are recorded in roadmap §2 with "(Human decision,
  YYYY-MM-DD)".
- **The design documents** in `doc/plans/` are references. Update the one that
  covers a ticket's work when the ticket lands. Do not restructure them.

## Milestone gate

1. **Tickets done.** Every ticket in the milestone is `done` (merged into `ng`).
   `./scripts/check.sh` passes on a **clean clone** of `ng`, made with
   `git clone --recurse-submodules` in a scratch directory, followed by
   `ocicl install`.
2. **Demo.** The milestone's demo runs end to end. Record the commands, the
   observed output and the evidence in `notes/gate-N/`. The evidence set:
   - `make test` counts for both dialects;
   - embed and liquid counts;
   - the conformance runner counts touched by the milestone, compared with
     `doc/harness/baselines.md`;
   - `bench/compare-ghc -n 3` tables for performance milestones;
   - ECL and ABCL counts compared with YHS-0.7's.
3. **CI.** The human pushes `ng`. The CI run on Ubuntu and macOS must be green,
   and its URL goes in the gate note. The reviewer may read CI results with
   `gh run list` / `gh run view` (read-only).
4. **Gate note.** The reviewer writes `notes/gate-N.md` (from
   `notes/templates/gate.md`), including a cross-ticket review, residual risks
   and roadmap amendments.
5. **Sign-off.** The human signs off by ticking the box in the gate note and
   committing (`signoff`). The `GATE-N` row becomes `done (signed off <initials>
   <date>)`.

## Escalation (builder stops and marks the ticket `blocked`)

- An external fact differs from the roadmap.
- An invariant or design document would have to change.
- The tests cannot pass within the ticket's scope.
- A new dependency, network access the ticket did not plan for, or a human
  decision is needed.
- A run would exceed the session. Record partial results and the exact command
  to resume.
