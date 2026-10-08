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
