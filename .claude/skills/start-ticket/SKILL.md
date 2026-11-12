---
name: start-ticket
description: Builder workflow to begin a Yale Haskell ticket (YHS-N.n). Picks the next eligible ticket from doc/harness/TICKETS.md (or the one named), checks dependencies, creates the local ticket branch from ng, marks it in-progress, records a baseline, and gathers the spec. Use when asked to "start", "pick up", "work on" a ticket or "the next ticket".
---

# start-ticket

Arguments: an optional ticket ID (`YHS-2.1`) or a track name (`K` for Milestone
3, `P` for Milestone 4). Without either, pick the next eligible ticket.

## Steps
1. **Sync.** Run `git status`. If the working tree is dirty, stop and report it.
   Otherwise run `git checkout ng`. Never pull or push; `ng` is updated by
   reviewers' local merges and pushed only by the human.
   - If the ticket touches MicroCabal, Hackage packages or Agda, run
     `git submodule update --init tools/microcabal/MicroCabal`.
2. **Choose the ticket.** Open `doc/harness/TICKETS.md`.
   - With an ID: its status must be `todo` or `changes-requested`, and every
     dependency must be `done`. Otherwise stop and list what is missing.
   - Without an ID: take the lowest-numbered eligible `todo` ticket, following
     the **Execution order** line in `doc/harness/roadmap.md` §2. Skip `GATE-*`
     rows; they belong to reviewers.
3. **Read the context** before writing code:
   - the ticket's row in `doc/harness/roadmap.md` §8, plus its milestone demo and
     pain points;
   - roadmap §3 (current state), §7b (correctness rung of the modules you
     touch), and the North-star hooks table;
   - the design reference the ticket names (`doc/plans/*.md`,
     `doc/STRATEGY.md`, `doc/EVAL-APPLY-GRIN.md`, `claude-prompt.md` §5);
   - `AGENTS.md` §4–§6;
   - handoff and review notes of the dependency tickets (`notes/<dep>.md`,
     `notes/<dep>.review.md`).
4. **Branch.** `git checkout -b ticket/<ID>-<short-slug>`. For
   `changes-requested`, reuse the existing branch.
5. **Mark in progress.** In `doc/harness/TICKETS.md`, set the status to
   `in-progress` and record the branch. Commit only that change:
   `<ID>: start (ticket board)`.
6. **Baseline.** Before changing anything, run `scripts/check.sh` (once YHS-0.3
   exists), or `make && make test` plus the ticket's test command. If it fails,
   stop and report it, because the cause is not your ticket. For performance
   tickets, take the "before" numbers now (`perf-change` skill).
7. **Plan.** Write down for yourself:
   - which files change;
   - which test proves each acceptance criterion, and where its expected output
     comes from (GHC 9.14.1 or the Report);
   - which domain skill applies (`yale-dev`, `correctness`, `perf-change`,
     `conformance-target`);
   - whether generated files or version numbers change (usually not).

   If a criterion is ambiguous, choose the reading most consistent with the
   roadmap and record it under "Deviations" in the handoff note. Do not stall.
8. Implement test-first where practical, then run `finish-ticket`.

## Do not
- Start a ticket whose dependencies are not `done`.
- Combine tickets on one branch.
- Push anything.
- Edit `doc/harness/roadmap.md`, `ref/`, the submodule, vendored test data or
  historical documents.
