# Gate <N>: <milestone name>

- **Reviewer:** <model name>
- **Date:** YYYY-MM-DD
- **ng at:** <sha>

## Tickets
| ID | Review note | Status |
|---|---|---|
| YHS-N.1 | notes/YHS-N.1.review.md | done |

## Clean-clone check
```sh
git clone --recurse-submodules -b ng <local repo path> <scratch>/gate-N && cd <scratch>/gate-N
ocicl install && ./scripts/check.sh
```
<result: exit code and decisive lines>

## Demo
> <the roadmap "Gate N demo" text, quoted>

```sh
<exact commands>
```
Observed:
```text
<observed output>
```
Evidence: `notes/gate-N/` (<screenshots / PDFs / logs>)

## Gate evidence (roadmap §8)
| Measure | Baseline (doc/harness/baselines.md) | Now | Command |
|---|---|---|---|
| `make test` (haskell98) | | | `make test` |
| Haskell 1.2 tests | | | `tests/run-tests tests/haskell-1.2` |
| embed / liquid | | | `make embed-test`, `make liquid-test` |
| conformance runners touched | | | |
| ECL / ABCL | | | `YALE_HASKELL_LISP=ecl tests/run-tests -j 8` |
| `bench/compare-ghc -n 3` (performance milestones) | | | |

## CI (from the human's push of ng)
- Run URL: <url>
- Ubuntu: <result>; macOS: <result>

## Cross-ticket review
- <duplication, inconsistent APIs or error formats, migrations from empty, drift from roadmap or design, north-star hooks>

## Residual risks
- <risk>: <mitigation or follow-up ticket>

## Roadmap amendments
- <change, or none>

## Human sign-off
- [ ] Approved: <initials> <date>
