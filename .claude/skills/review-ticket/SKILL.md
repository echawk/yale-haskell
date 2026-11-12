---
name: review-ticket
description: Reviewer workflow for a Yale Haskell ticket (YHS-N.n) in `review` status. Independently re-runs the tests, checks expected outputs against GHC, tries adversarial programs and compiler configurations, checks invariants, correctness rungs and north-star hooks, writes notes/<ID>.review.md, then merges into ng with --no-ff or requests changes. Use when asked to review a ticket or check a builder's work. Intended for higher-tier models.
---

# review-ticket

Argument: a ticket ID. Without one, take the oldest `review` ticket in
`doc/harness/TICKETS.md`.

**Stance:** do not trust the handoff note. Every "yes" must be confirmed by a
check you ran yourself. The adversarial step is where most real bugs are found.

## Steps
1. **Read** `notes/<ID>.md`, the ticket row in `doc/harness/roadmap.md` §8, the
   roadmap sections it relies on (§3, §7b, North-star hooks), and the design
   reference it names.
2. **Check out the branch.** Run `git diff ng...HEAD --stat`, then read the full
   diff.
3. **Verify independently.**
   - Prefer a fresh local clone of the branch in a scratch directory:
     `git clone -b ticket/<ID>-<slug> <repo path> <scratch>/<ID>`, then
     `ocicl install`, `make`, `make test`, and `scripts/check.sh` (once it
     exists). Set `YALE_HASKELL_CACHE_DIR` to a scratch directory so your cache
     is cold. Long runs go through `tools/bound`.
   - For each acceptance criterion, find and read the test that proves it. A
     test that only checks "no crash" does not count. A criterion with no real
     test is a required change.
   - Check at least one new `.stdout` against `ghc` 9.14.1 yourself
     (`ghc -O0 T.hs && ./T`).
   - **Adversarial cases (mandatory).** Run at least 3 inputs the builder
     probably did not test. Typical sources:
     - the same program under `-O`, `--backend flic`, `-g none`,
       `--ghc2021`, `--haskell1.2` where meaningful;
     - `YALE_HASKELL_SAFETY=3` (after YHS-1.1);
     - boundaries: empty lists and strings, `maxBound :: Int`, deep recursion,
       large `Integer`, Unicode text, a module that imports itself indirectly;
     - a cold unit cache, and a second run that uses the warm cache;
     - for library work, the law the instance must obey (QuickCheck under both
       Yale and GHC).
   - **Correctness rung:** confirm the touched modules carry the evidence their
     rung requires (roadmap §7b). For optimizer, back-end or performance
     tickets, re-run the metamorphic runner and (after YHS-2.6) a fuzz run
     longer than the builder's. Run `scripts/check.sh --ratchet` (after
     YHS-0.4).
   - **Performance tickets:** re-run `bench/compare-ghc -n 3` for the affected
     programs and compare with the builder's `bench/RESULTS.md` section.
4. **Checklist** from `doc/harness/agent-protocol.md`. Pay special attention to:
   - expected outputs copied from Yale's output;
   - raw dialect checks instead of `feature?`;
   - SBCL-only calls outside `#+sbcl`;
   - interface files changed in one place only;
   - Haskell 1.2 regressions;
   - scope creep and new dependencies;
   - closed-off north-star hooks.
5. **Write `notes/<ID>.review.md`** from `notes/templates/review.md`. Give each
   required change as `path:line: problem. fix. why it matters`. Answer the
   builder's questions with decisions.
6. **Approve.** Run `git checkout ng && git merge --no-ff ticket/<ID>-<slug> -m
   "Merge <ID>: <title>"`, re-run `make test` on `ng`, set the ticket to `done`
   in `doc/harness/TICKETS.md`, and commit the review note and the board change
   on `ng` (`<ID>: review approved`). **Do not push**; the human pushes `ng`.
7. **Request changes.** Commit the review note on the branch (`<ID>: review,
   changes requested`) and set the ticket to `changes-requested`. On re-review,
   append `## Round 2` to the same review note.
8. **Roadmap amendments.** If reality differs from the roadmap (a tool fact, a
   count, a "verify" item settled), edit `doc/harness/roadmap.md` and record the
   change under "Roadmap amendments".
9. If this was the last ticket of a milestone, announce that the gate is ready
   (`milestone-gate`).
