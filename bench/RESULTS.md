# Benchmark results

## Baseline (before any eval/apply work)

- Date: 2026-10-07
- Commit: 3f1e72e (branch `ng`, unmodified compiler)
- SBCL 2.6.9, Apple M4 (arm64), macOS
- `bench/run-bench`, 3 runs per program, Haskell 98 dialect
- Fixed overhead (hello world: image start-up plus trivial compile):
  min 0.079 s, median 0.084 s.  Compile time is not reported separately
  (see README), so `min-ovh`/`med-ovh` = total minus that overhead.

| program | min (s) | median (s) | min-ovh | med-ovh | check |
|---|---|---|---|---|---|
| bigint    | 0.897 | 0.903 | 0.818 | 0.819 | ok |
| integrate | 0.960 | 0.979 | 0.881 | 0.895 | ok |
| ioloop    | 2.316 | 2.847 | 2.237 | 2.763 | ok |
| nfib      | 1.160 | 1.503 | 1.081 | 1.419 | ok |
| queens    | 1.771 | 2.072 | 1.692 | 1.988 | ok |
| sieve     | 1.472 | 1.775 | 1.393 | 1.691 | ok |
| tree      | 1.902 | 1.962 | 1.823 | 1.878 | ok |
| wheel     | 1.287 | 1.324 | 1.208 | 1.240 | ok |

Expected outputs were also cross-checked against an independent Python
implementation (nfib, queens count, primes, Hamming, Integer results,
Simpson integral).  Timings vary by up to about 25% run to run (nfib,
ioloop, sieve, queens); use several runs.

## Optimizer enabled for user programs (2026-10-08)

Until this change `tools/build/image.lisp` compiled user programs with
`*optimizers* '()`: no inlining, no strictness-based unboxing, and every
overloaded operation through a dictionary (only the prelude was
optimized).  The baseline above therefore measured unoptimized code.
With `*all-optimizers*` the test suite passes unchanged, and nfib(32)
went from about 1.2 s to 0.05 s; queens(11) from 1.7 s to 0.04 s.  nfib
and queens were enlarged (nfib 40, queens 12) so they still measure
something; the other programs are unchanged.

- Commit: optimizer change on `ng` (after e9ac14d), SBCL 2.6.9, Apple M4
- The machine was noticeably slower than on 2026-10-07 during this run
  (the old baseline image also ran ~1.5x slower then), so compare
  numbers taken in the same session only.

```
runs per program: 3;  fixed overhead (hello world): min 0.113 s, median 0.119 s
program           min   median    min-ovh  med-ovh  check
bigint          1.282    1.284      1.169    1.165  ok
integrate       0.360    0.374      0.247    0.255  ok
ioloop          2.961    3.082      2.848    2.963  ok
nfib            0.956    1.041      0.843    0.922  ok
queens          1.122    1.145      1.009    1.026  ok
sieve           1.405    2.157      1.292    2.038  ok
tree            0.984    0.986      0.871    0.867  ok
wheel           0.806    0.846      0.693    0.727  ok
```
