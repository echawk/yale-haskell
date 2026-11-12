# YHS-0.2: Z3 query timeout in yale-liquid

Status: review

## Hanging query

`tests/liquid/fq/pos/hex.ts.fq` (already listed in `fq/expected-failures.txt`,
"bit-vector theory not encoded"). Found by running the fq files one at a time
under `tools/bound`: the run stopped on that file, and `z3 -smt2` sat at 100% CPU.
The query is the first `(check-sat)` after `(assert (not (Prop |VV#1|)))` over
string-sorted `ttag` terms. Run on the logged script, Z3 5.3.3 ignores
`(set-option :timeout 2000)`, `-t:2000` and SIGINT. Only `-T:5` (hard, whole
process) stops it.

## Change

- `src/liquid/z3.lisp`:
  - `(set-option :timeout N)` is sent at session start. N comes from
    `*z3-timeout-ms*`, else `$YALE_LIQUID_Z3_TIMEOUT` (seconds), else 10 s.
  - Because the soft timeout does not always fire, `z3-check-sat` reads with a
    clock (`z3-read-line`, timeout plus 2 s). On expiry it kills Z3, starts a new
    process, replays the commands of the open scopes (kept per scope in
    `z3-history`), reports `yale-liquid: Z3 query timed out after N ms: <label>
    (query K); result unknown` on stderr, and returns `:unknown`.
  - After any `unknown` it asks `(get-info :reason-unknown)` and reports soft timeouts the same way.
- `src/liquid/fixpoint.lisp`: `solve-fq-file` binds `*z3-query-label*` to the file name.
- `src/liquid/package.lisp`: exports `*z3-timeout-ms*`, `*z3-query-label*`, `z3-timeouts`.
- Tests: `tests/liquid/tests.lisp` section "per-query Z3 timeout" (soft path with a
  hard bit-vector problem; hard path with `tests/liquid/hang-z3.sh`, a silent stand-in solver).
- Docs: `doc/plans/LIQUID-HASKELL.md` section 5.1, `tests/liquid/README.md`.

## Evidence

- `tools/bound 150 make liquid-test`: finishes in about 54 s, `OK: 0 failures
  (69 unit checks)` (baseline 65, plus 4 new), pos 96/109 SAFE, neg 38/39 UNSAFE
  (counts unchanged). Two timeout lines are printed, both for `hex.ts.fq`.
- `make test`: 925 passed, 0 failed (4 min 55 s). The Haskell 1.2 suite was not re-run: no compiler or runtime file changed, only `src/liquid/`.
- No `z3` or `hang-z3` processes were left behind.

## Deviations

- Acceptance (2) says "default 10 s ... reported as unknown naming the query".
  Done. The reporting goes to stderr, and the result value is `:unknown`.
- The timeout is per `(check-sat)`, implemented by a clock watch plus restart,
  since Z3's own timeout is not reliable (see above).

## Hooks

No north-star hook is affected.
