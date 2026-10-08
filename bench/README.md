# Benchmarks

nofib-style programs for measuring the back end (phase P0 of
`doc/EVAL-APPLY-GRIN.md` section 10).  Each is a self-contained Haskell 98
file in the dialect `--haskell98` supports (no records, qualified names or
hierarchical modules) that prints a short deterministic result; `NAME.stdout`
holds the expected output, so every run also checks correctness.

## Running

    make bench                    # builds if needed, 3 runs per program
    bench/run-bench               # same, without the build step
    bench/run-bench -n 5 nfib tree   # 5 runs of selected programs

`run-bench` prints, per program, the minimum and median wall-clock seconds
of a full `bin/yale-haskell --haskell98 NAME.hs` run, and the same minus the
fixed overhead, plus `ok`, `WRONG` (output differs from `.stdout`) or `FAIL`
(nonzero exit).  The exit status is 1 if any program is not `ok`.

**Compile time is not separated.**  The batch driver compiles and runs in
one process and prints no phase times, so the harness times
`_overhead.hs` (hello world: image start-up plus compiling a trivial
module) and subtracts it (`min-ovh`, `med-ovh`).  What remains is
compile-of-the-program plus run time; for these small programs compilation
is a small part, but it is not zero.  Compare `min-ovh` across revisions,
and run on an otherwise idle machine.

## Programs

| Program | Stresses |
|---|---|
| `nfib` | Known calls, `Int` arithmetic and comparison, no allocation |
| `queens` | List comprehensions, `and`/`zip`, higher-order list code, allocation |
| `sieve` | Naive lazy sieve: nested thunks and filters over an infinite list |
| `wheel` | Lazy streams: Hamming numbers via mutually recursive `merge`, a wheel-based prime generator using a self-referential lazy list |
| `bigint` | `Integer` (bignum) `product`, `zipWith` fibonacci, `show` of large numbers, `^` and `mod` |
| `integrate` | `Double` arithmetic, `sin`/`exp`/`sqrt`, strict accumulator loops, `fromIntegral` |
| `tree` | Algebraic data and pattern matching: binary search tree insert/lookup/size/depth |
| `ioloop` | `writeFile`/`readFile`, `lines`, `read`, `mapM_` over 200000 elements; output goes to `/tmp` so stdout stays short |

## Recording results

Run `make bench` on an idle machine, then update `bench/RESULTS.md`: date,
`sbcl --version`, the git commit, the machine, and the table.  Each phase
of the plan adds a section rather than overwriting the baseline.  Do not
change program sizes without re-recording the baseline (and regenerate
`.stdout` only after checking the new answer independently).
