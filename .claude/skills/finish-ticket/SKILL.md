---
name: finish-ticket
description: Builder workflow to hand a Yale Haskell ticket (YHS-N.n) to review. Runs make test on both dialects and scripts/check.sh, self-reviews the diff against acceptance criteria and AGENTS.md invariants, writes notes/<ID>.md with evidence, sets status to review in doc/harness/TICKETS.md, and commits locally. Use when implementation of a ticket is complete or blocked.
---

# finish-ticket

## Steps
1. **Run the checks** on SBCL:
   - the ticket's test command (long ones under `tools/bound`);
   - `make test`;
   - `make haskell-1.2 && tests/run-tests tests/haskell-1.2`;
   - `scripts/check.sh` once YHS-0.3 exists (it includes the above and the
     ratchet).

   All must pass. A test that needs a missing tool (z3, ghc, mallet, the
   submodule) must skip with a message. If the checks cannot pass within scope,
   go to step 7 with status `blocked`.
2. **Generated files.** If the ticket could affect files produced by
   `tools/gen/*` or other scripts, regenerate them with the script, never by
   hand. Regenerate a second time: the output must be identical.
3. **Self-review** `git diff ng...HEAD`, checking that:
   - every acceptance criterion has a test or a reproducible command as evidence;
   - new tests' expected output came from GHC 9.14.1 or the Report, not from Yale;
   - every changed file is in scope;
   - these AGENTS.md §5 invariants hold:
     - `feature?` gating, never raw `(haskell98?)`;
     - host-specific calls only behind `#+` in `src/mumble/` or `src/runtime/`;
     - readable `|Module:name|` generated names;
     - interface-file round trip (all three files changed together);
     - Haskell 1.2 behaviour unchanged;
     - every optimizer pass can still be switched off by name;
   - the correctness rung of each touched module is met (roadmap §7b), and
     `scripts/check.sh --ratchet` passes (after YHS-0.4), with no new
     suppression or `.xfail` without a justification and a ticket ID;
   - the north-star hooks (AGENTS.md §6) are preserved;
   - there is no debug output, no commented-out code, and no TODO without a
     ticket ID;
   - the covering `doc/plans/*.md` is updated, and for performance work a dated
     section was appended to `bench/RESULTS.md`.
4. **Fix** what the self-review finds, then repeat steps 1–3.
5. **Evidence.** Save logs, result tables and benchmark output to
   `notes/<ID>/`. Keep each file small; trim to the decisive lines.
6. **Write `notes/<ID>.md`** from `notes/templates/handoff.md`. Fill in every
   section, especially the evidence table and the environment notes (cache
   directory, `CABALDIR`, wall times of long runs). Paste the decisive output
   lines, such as `925 passed, 0 failed, ...`; do not just write "tests pass".
7. **Update the board.** In `doc/harness/TICKETS.md`, set the status to `review`,
   or to `blocked` with the exact blocker and what would unblock it.
8. **Commit locally** with the ticket ID: `<ID>: <summary sentence>`. Do not
   push. Do not merge.
9. **Report** to the user in 3–5 lines: ticket, status, branch, test results,
   open questions.
