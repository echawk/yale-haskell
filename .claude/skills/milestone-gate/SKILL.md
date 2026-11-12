---
name: milestone-gate
description: Reviewer workflow to close a Yale Haskell milestone (GATE-N). Verifies all tickets done and merged into ng, runs scripts/check.sh on a clean clone, executes the roadmap's gate demo, collects gate evidence (test counts, conformance counts vs doc/harness/baselines.md, ECL/ABCL counts, bench tables), asks the human to push ng and records the CI result, writes notes/gate-<N>.md, and requests human sign-off. Use when asked to "run gate N" or close a milestone.
---

# milestone-gate

Argument: the milestone number N (including inserted milestones like `1.5`).

## Steps
1. **Tickets done.** In `doc/harness/TICKETS.md`, confirm every `YHS-N.*` ticket
   is `done` (merged into `ng`) and has a review note. If any is not, stop and
   list them.
2. **Clean-clone check.** In a scratch directory outside the working tree, run
   `git clone --recurse-submodules -b ng <repo path> <scratch>/gate-N`, then
   `cd` there, `ocicl install` and `scripts/check.sh`. Set
   `YALE_HASKELL_CACHE_DIR` to a fresh scratch directory. Record the exit code
   and decisive lines.
3. **Run the demo.** Execute "Gate N demo" from `doc/harness/roadmap.md` §8.
   Record the exact commands and observed output in `notes/gate-N/`.
4. **Gate evidence** (roadmap §8 intro). Fill the evidence table in the gate
   note:
   - `make test` counts for both dialects;
   - `make embed-test` and `make liquid-test`;
   - the conformance runner counts touched by the milestone, compared with
     `doc/harness/baselines.md`;
   - ECL and ABCL counts (`make LISP=ecl`, `YALE_HASKELL_LISP=ecl tests/run-tests
     -j 8`, the same for abcl), compared with YHS-0.7's counts;
   - for performance milestones, `bench/compare-ghc -n 3`, appended to
     `bench/RESULTS.md`.

   Run long commands under `tools/bound`. A lowered count is a regression:
   either it gets a follow-up ticket or the gate fails.
5. **CI.** Ask the human to push `ng`. Agents never push. When they have, read
   the result with `gh run list -b ng -L 1` and `gh run view <id>`. Record the
   run URL and the Ubuntu and macOS results in the gate note. A red CI fails the
   gate until a follow-up ticket fixes it.
6. **Cross-ticket review:**
   - duplicated helpers;
   - inconsistent command-line flags or environment variables;
   - drift from `doc/plans/*` or the roadmap;
   - `.xfail` files added during the milestone and their tickets;
   - ratchet counts;
   - north-star hooks;
   - whether `README.md` and `doc/plans/*` status tables reflect the new counts.
7. **Write `notes/gate-N.md`** from `notes/templates/gate.md`. Apply any roadmap
   amendments, update `doc/harness/baselines.md` with the new counts, and add
   follow-up tickets to `doc/harness/TICKETS.md` if needed. Commit on `ng`
   (`GATE-N: gate report`).
8. **Sign-off.** Set the `GATE-N` row to `review` and ask the human to sign off:
   tick the box in the gate note and commit `signoff`. Then set the row to
   `done (signed off <initials> <date>)`.
