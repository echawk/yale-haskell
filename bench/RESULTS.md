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

## P1 thunks, then inlined mumble primitives (2026-10-08)

P1 (thunks distinguishable from data, blackholing) was measured against
`ng` with the optimizer on, interleaving old and new runs, best of 3:
within noise everywhere, tree -21% and ioloop -8%.  A first version with
a struct thunk (4 words on SBCL/arm64) and mumble's `eq?`/`pair?` in the
hot path was 15-60% slower; profiling showed those mumble predicates
were full function calls.

Cause: `define-mumble-function-inline` (src/mumble/cl-support.lisp)
used `proclaim` at load time, so no inline expansion was ever recorded
for mumble's primitives (`eq?`, `pair?`, `null?`, `car`...).  With
`declaim`, same session, total minus overhead:

```
bigint      0.707 ->  0.697  (-1%)
integrate   0.147 ->  0.132  (-10%)
ioloop      1.449 ->  1.205  (-17%)
nfib        0.563 ->  0.578  (+3%)
queens      0.506 ->  0.421  (-17%)
sieve       0.956 ->  0.766  (-20%)
tree        0.704 ->  0.544  (-23%)
wheel       0.734 ->  0.534  (-27%)
```

## P2 eval/apply (2026-10-08)

Function values became `fun` structs (arity + fixed-arity entry), unknown
calls `apply-1`..`apply-4`/`apply-n` instead of `&rest` closures,
constructors as values and nullary constructors preallocated.  Measured
against `0ad4c55`, alternating old and new images, total minus
overhead, median of 3, two rounds each (the machine was slower than in
the previous session):

```
             base (2 rounds)    P2 (2 rounds)
bigint       1.612  1.570       1.351  1.444   (-10%)
integrate    0.334  0.347       0.344  0.443   (noise; 5-run repeats go both ways)
ioloop       2.875  3.143       2.330  2.616   (-15%)
nfib         1.120  1.180       1.116  1.168   (same)
queens       1.055  1.058       0.940  1.034   (-3% in 5-run repeats)
sieve        2.139  2.290       1.386  1.398   (-37%)
tree         1.534  1.490       1.285  1.298   (-15%)
wheel        1.277  1.251       0.759  0.748   (-40%)
```

## P3 case recovery and strict seq (2026-10-08, numbers pending)

P3 (CL `case` from `if` chains) measured within noise on the existing
programs, which dispatch almost only on lists and Bool (two-way, left
as `if`).  `interp.hs` was added as a dispatch-heavy program, but its
time was dominated by `seq`: `strict1` was `Strictness("S,N")`, so
``x `seq` e`` built a thunk for `e` every step and the interpreter loop
was analysed as lazy in its registers.  With `seq` strict in both
arguments, interp went from about 1.40 s to 0.85 s total (one
unloaded run each).  Proper P3 and seq numbers wait for a quiet
machine.

## P5 step 1: Int/Integer division primitives, eval inlining (2026-10-08)

Profiling (`make profile FILE=…`) showed `mod`/`div` on Int going
through the Report's class defaults (`default-divMod`, `signumReal`:
thunks and closures per call), 30-50% of sieve, wheel, interp and tree;
and `force` as a full call, 8-21% self time everywhere.  `Integral
Int`/`Integer` now define quot/rem/div/mod/divMod with primitives (CL
truncate/rem/floor/mod), and GRIN emits `eval` as the inline
`force-inline` test.

The machine was loaded (load average 12-17), so these are CPU seconds
(user+sys, whole process including ~0.15 s start-up), P4 (9e60a16) vs
P5 alternating, three runs each:

```
            P4                  P5
nfib        1.37 1.34 1.35      1.37 1.37 1.36
queens      1.46 1.34 1.43      1.17 1.11 1.21    -18% (eval inlining)
sieve       1.90 1.87 1.97      0.27 0.27 0.27    7x
tree        1.55 1.62 1.63      1.08 1.10 1.16    -30%
wheel       1.12 1.17 1.08      0.18 0.19 0.17    6x
integrate   0.60 0.57 0.59      0.63 0.58 0.58
interp      1.19 1.35 1.28      0.46 0.47 0.46    2.8x
ioloop      2.92 2.79 2.93      2.41 2.47 2.64    -13%
bigint      1.72 1.70 1.72      1.71 1.81 1.89
```

Allocation during main (bytes consed, independent of load): sieve
1508 MB -> 133 MB, wheel 1219 -> 14, interp 844 -> 178, tree 866 -> 574;
queens, integrate and ioloop unchanged.

## P5 step 2: even/odd, show for Int/Integer, chunked string conversion

Further profile-driven fixes: `even`/`odd` were class defaults (22% of
integrate); `show` on Int/Integer peeled digits with `quotRem n 10`
(quadratic on bignums, half of bigint) and now prints with Lisp; and
`make-haskell-string` built one thunk per character, now one per
32-character chunk (ioloop's top entry).  CPU seconds, P4 vs now,
alternating (load average ~17):

```
            P4                  now
integrate   0.58 0.59 0.60      0.49 0.51 0.46    -17%
ioloop      3.13 3.19 2.99      2.06 2.03 2.08    -34%
bigint      1.70 1.81 1.84      0.50 0.56 0.50    3.4x
tree        1.72 1.68 1.79      1.22 1.15 1.06    -32%
queens      1.32 1.32 1.44      1.12 1.16 1.17    -15%
```

## P5 complete: speculation and constant folding (2026-10-08)

GRIN passes (src/compiler/grin/grin-opt.mumble): `encode-double`
of literals folded at compile time; `delay` of a literal, of an
evaluated variable, or of `eval v` removed; and speculation (dynamic
cheap eagerness): a suspended small expression of total Int/Char (and,
in Haskell 98, Float/Double) primitives is computed at once when its
inputs are already evaluated.  Lazy numeric accumulators (integrate's
orbit) stay evaluated: allocation 213 MB -> 65 MB.

Final P4 (9e60a16) vs P5, CPU seconds (user+sys, whole process), machine
quiet (load ~2.7), alternating:

```
            P4                  P5
nfib        0.60 0.65 0.64      0.62 0.62 0.65
queens      0.58 0.55 0.55      0.45 0.44 0.46    -20%
sieve       0.73 0.75 0.73      0.10 0.09 0.10    7x
tree        0.64 0.63 0.63      0.37 0.38 0.40    -40%
wheel       0.51 0.52 0.52      0.06 0.06 0.07    8x
integrate   0.24 0.24 0.24      0.07 0.07 0.07    3.4x
interp      0.50 0.50 0.53      0.17 0.18 0.17    2.9x
ioloop      1.33 1.27 1.29      0.82 0.82 0.83    -36%
bigint      0.75 0.74 0.74      0.19 0.19 0.20    3.8x
```

## P6 feasibility: whole-program compilation, and the gap to GHC (2026-10-08)

**Whole-program by source.**  A program can be compiled as extra modules
of the Prelude unit (a `.hu` with `:prelude`, every Prelude source and
`Main`), giving one big FLIC let for the optimizer and GRIN.  It works
unchanged, but with today's passes it is never faster and sometimes
slower than separate compilation.  Run-only CPU seconds (main only,
same harness, two runs):

```
            separate        whole-program
nfib        0.82 0.83       0.83 0.82
queens      0.54 0.57       0.67 0.64
sieve       0.05 0.05       0.19 0.16
tree        0.60 0.58       0.77 0.65
integrate   0.03 0.03       0.09 0.09
ioloop      1.30 1.26       1.42 1.26
bigint      0.19 0.20       0.31 0.31
```

**The gap to GHC 9.14** (same programs, `Data.Array` for `Array`), CPU
seconds of the compiled program:

```
            Yale (run)   GHC -O0   GHC -O2
nfib        0.82         8.5       0.42
queens      0.55         2.95      0.21
sieve       0.05         0.08      0.03
tree        0.59         0.67      0.40
wheel       0.01         0.07      0.01
integrate   0.03         0.62      0.17
interp      0.18         0.37      0.07
ioloop      1.28         0.21      0.19
bigint      0.20         0.14      0.11
```

Compute benchmarks are within 1.5-2.6x of GHC -O2 (integrate is faster,
thanks to speculation); the one large gap is ioloop (6.7x), which is I/O,
`lines` and `read` in the libraries, not something whole-program
analysis addresses.

## Fast decimal read for Int/Integer (2026-10-08)

ioloop was the one large gap to GHC (6.7x).  Its profile was dominated
by the Report's `readSigned readDec` (general `lex`, several list
comprehensions per number).  `readSignedDec` (PreludeNumeric) takes a
fast path for spaces, an optional `-` and decimal digits when nothing
can continue the number token, and otherwise the Report definition;
tests/haskell98/prelude/read-integral.hs checks they agree.  ioloop
allocation 2.16 GB -> 0.91 GB; CPU, alternating with a984b68:
1.00 0.99 1.01 -> 0.49 0.48 0.51 (2x).

## Self-local calls, code quality for programs, representation types

GRIN emission: a function that calls itself is emitted with its body as
a `labels` function of the same name, so self-calls are local calls (a
5-argument self tail loop runs 4x faster in plain SBCL).  Programs run by
bin/yale-haskell are compiled in-core, which never applied
`*code-quality*`: they got SBCL's default policy (speed 1, safety 1)
while the Prelude got speed 3, safety 0; now both do.  And the minimal
representation types of section 9: strict Int/Char parameters of
top-level functions are declared fixnum (Double/Float likewise).
New benchmark `loop` (strict 5-accumulator loop), CPU seconds vs
a984b68: 0.52 -> 0.26 (GHC -O2: 0.22).  The other benchmarks are
unchanged: their time is allocation, laziness and non-tail calls.

## Inline Ix index/inRange for Int, Char, Integer

Array indexing called `i-Ix-Int-index/OPT` (and `inRange`) per access;
only `range` had an `Inline` pragma.  With `index` and `inRange` inlined
too, interp's run time (main only) 0.162 -> 0.104 s.

Run-only CPU seconds vs GHC 9.14 -O2 at this point (quiet machine):

```
            Yale    GHC -O2
nfib        0.60    0.27
queens      0.38    0.14
sieve       0.04    0.01
tree        0.29    0.19
wheel       0.01    0.00
integrate   0.02    0.14
interp      0.10    0.06
ioloop      0.51    0.14
bigint      0.17    0.09
loop        0.29    0.25
```

## Modern-Haskell benchmarks and bench/compare-ghc (2026-10-10)

`bench/modern/` adds programs that use the libraries and extensions of
the conformance work (all run with `--haskell98 --modern-prelude`):
`mapcount` (Data.Map.Strict, Data.Set, Data.IntMap), `statemonad`
(Control.Monad.State.Strict with a record state), `starray` (a 10^7
sieve in an STUArray), `ioref` (Data.IORef, forM_), `foldable` (derived
Functor/Foldable/Traversable on a rose tree), `existential`
(ExistentialQuantification and a constrained rank-2 argument).

`bench/compare-ghc` runs every bench program with Yale and with
`ghc -O0`/`-O2` (GHC 9.14.1).  Yale's time is the CPU time of running
`main` only (`YALE_HASKELL_TIME=1`: compilation and start-up excluded);
GHC's is the whole process.  Commit 94bd47e plus this section's
library changes, SBCL 2.6.9, Apple M4.  `YALE_HASKELL_PROFILE=1`
profiles `main` (sb-sprof).

First run, before any of the fixes below:

```
program          Yale    Yale MB  GHC -O0  GHC -O2    ratio
foldable        1.918       2104    0.562    0.227     8.5x
ioref           2.617       4853    0.448    0.016   161.9x
mapcount            -  (IntMap.foldr missing)
starray        17.295      37570    2.709    0.051   336.2x
statemonad          -  (control stack exhausted)
existential         -  (constrained polytype: not supported)
```

After the fixes:

```
CPU seconds, best of 3; Yale: running main only
program          Yale    Yale MB  GHC -O0  GHC -O2    ratio  check
bigint          0.157        553    0.083    0.078     2.0x  ok
integrate       0.019         58    0.338    0.105     0.2x  ok
interp          0.073        176    0.240    0.050     1.5x  ok
ioloop          0.405        921    0.127    0.117     3.5x  ok
loop            0.200          0   13.989    0.217     0.9x  ok
nfib            0.580          0    5.871    0.297     2.0x  ok
queens          0.417        674    2.072    0.147     2.8x  ok
sieve           0.039        132    0.048    0.019     2.1x  ok
tree            0.315        584    0.346    0.209     1.5x  ok
wheel           0.006         13    0.056    0.009     0.6x  ok
existential         -          0    0.060    0.022        -  FAIL (constrained polytype)
foldable        1.687       1836    0.560    0.226     7.5x  ok
ioref           0.041          0    0.459    0.015     2.8x  ok
mapcount        0.954       1542    0.335    0.272     3.5x  ok
starray         0.194         80    2.530    0.050     3.9x  ok
statemonad      0.141        418    0.605    0.023     6.2x  ok
```

Yale beats GHC -O0 on every program but bigint and ioloop, and
GHC -O2 on integrate, wheel and loop (speculation keeps the lazy
accumulators evaluated); the Haskell 98 programs are 1.5-3.5x GHC -O2.

What the new programs found and what was done:

- **Tuple patterns were lazy.**  Matching a single-constructor pattern
  did not evaluate the value (`case undefined of (a, b) -> 1` was 1):
  strict State built thunk chains until the stack overflowed, and
  nofib's spectral/simple leaked 4 GB (it now passes: nofib 68).
- **Mutable arrays.**  `freeze`/`unsafeFreeze` went through a list of all
  elements; now a vector copy / no copy (an Array's vector holds the
  same values).  The `MArray` methods, `readArray`/`writeArray`, IO's and
  ST's binds, `thenIO_`, `when` and `unless` are inlined.
- **Optimizer.**  `seq x (\s -> e)` becomes `\s -> seq x e` (eta through
  a bang pattern: an ST loop takes its state argument instead of
  returning a closure each iteration); `getRes`/`getState` of a known
  `returnIO` fold, so an IO result is not a thunk forced at once; a
  single-constructor test is `seq`.  starray: 17.3 s -> 0.19 s.
- **Dictionary functions.**  A method selected from an instance's
  dictionary function applied to dictionaries (`Monad (StateT s m)` at
  `Identity`) folds to the instance method, which then inlines.
  statemonad: 3.9 s -> 0.14 s; ioref (forM_, modifyIORef' inlined):
  2.6 s -> 0.04 s.
- **apply-1..4** pasted their argument forms into both branches,
  doubling code at each level of nested unknown calls (spectral/simple
  then hit SBCL's 2047-functions-per-component limit).

What remains: foldable's `traverse` in `Maybe` (1.4 s of its 1.7 s) and
mapcount's `Ord Int` comparisons inside Data.Map's recursive
operations are dictionary calls in recursive overloaded functions,
which no amount of inlining reaches: doc/plans/SPECIALIZE.md.
`existential` needs constrained polytypes (CONFORMANCE.md).
