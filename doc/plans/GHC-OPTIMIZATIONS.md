# GHC's optimisations, and where each goes in Yale Haskell

Status: reference and plan (2026-10-10).  For each optimisation GHC
performs, from the desugarer to the runtime, this gives what it does,
what Yale Haskell already has that does the same job (with the file),
and where it would go in Yale's pipeline.  The last section orders the
missing ones by expected value, measured against `bench/compare-ghc`
(bench/RESULTS.md).

GHC references: the GHC User's Guide, "Optimisation (code
improvement)" (the `-f` flags named below); `GHC.Core.Opt.Pipeline`
(`getCoreToDo`, which lists the Core-to-Core passes and their order);
and the papers named for each pass.

## 1. The two pipelines side by side

GHC (at `-O`/`-O2`):

```
parse  rename  typecheck  desugar ──► Core
Core-to-Core:  simplify ⇄ { specialise, float-out, float-in, call-arity,
               demand analysis + worker/wrapper, CPR, CSE, liberate-case,
               SpecConstr, exitification, late specialise / late demand }
CorePrep (ANF, saturation) ──► STG
STG:  unarise, STG CSE, late lambda lifting, tag inference
STG ──► Cmm:  closure layout, pointer tagging, let-no-escape as jumps
Cmm:  sinking, common-block elimination, control-flow shortcutting,
      block layout, proc points, stack layout
NCG or LLVM:  instruction selection, register allocation
RTS:  generational copying GC, selector-thunk elimination, eager/lazy
      blackholing, static INTLIKE/CHARLIKE closures
```

Yale Haskell (`compile-modules`, `src/compiler/top/phases.mumble`):

```
parse  import-export  type-decls  scope  depend  type  cfn  depend2
ast-to-flic ──► FLIC
optimize  (src/compiler/backend/optimize.mumble: up to 15 iterations
          of one rewrite walk, with foldr/build at fixed iterations)
strictness (backend/strictness.mumble: Consel's fixpoint analysis)
          + box analysis (backend/box.mumble: boxed or not, delay or
          compute eagerly)
grin-lower ──► LGRIN  (src/compiler/grin/grin-lower.mumble: eval and
          delay explicit, case from test chains)
grin-opt  (grin/grin-opt.mumble: fold, speculate, inline-eval,
          self-local, rep-types, ftype)
grin-emit ──► Common Lisp ──► SBCL's compiler (its own constraint
          propagation, register allocation, tail calls)
runtime:  src/runtime (thunks with blackholing, eval/apply), SBCL's
          generational GC
```

The correspondence:

| GHC stage | Yale stage | Notes |
|---|---|---|
| desugarer (pattern matching) | cfn (`cfn/pattern.mumble`) | |
| Core | FLIC | Both are small lambda languages.  FLIC has `case-block`/`return-from` where Core has `case` with join points. |
| simplifier | optimize | |
| demand analysis | strictness + box | |
| CorePrep, STG | grin-lower, LGRIN | |
| Cmm, NCG | grin-emit, then SBCL | |
| RTS | src/runtime + SBCL's runtime | |

## 2. The catalogue

Status key:

- **have:** Yale does this (partly or fully).
- **partial:** a narrower form exists.
- **missing**
- **n/a:** SBCL or the Lisp runtime does it, or it does not apply.

"Place" names the Yale phase and file where the work belongs.

### 2.1 Desugaring and type-directed

| GHC | What it does | Yale status | Place |
|---|---|---|---|
| Pattern-match compilation (`GHC.HsToCore.Match`) | Decision trees for overlapping equations | **have**: cfn builds `case-block`s.  The optimizer removes redundant constructor tests (`case-block-discard-redundant-test`) and turns blocks into `if` (`case-block-to-if`), and P3 recovers CL `case` | cfn, optimize, grin-lower |
| Overloaded literals at known types | `fromInteger 3 :: Int` becomes the literal | **have**: `integer-to-int-constant-fold`, `int-to-integer-*`, `rational-to-*` (`magic-optimize-function`) | optimize |
| Defaulting, dictionary construction | `Num a` resolved to `Int` at compile time | **have** (the type checker) | type |
| `-fdicts-cheap`, `-fdicts-strict` | Treat dictionaries as cheap (eta-expand through them) and strict | **missing**.  Dictionaries are delayed like any argument.  Marking dictionary parameters strict is simple, in strictness: they are always evaluated tuples | strictness |

### 2.2 The simplifier (GHC's workhorse)

GHC's simplifier runs repeatedly, in phases 2, 1, 0, between the other
passes.  Yale's `optimize` is the same kind of iterated rewrite walk;
Loosemore's 1993 note, *Secrets of the Yale Haskell Optimizer
Revealed* (doc/optimizer/optimizer.dvi), describes it.

| GHC | What it does | Yale status | Place |
|---|---|---|---|
| Inlining with unfoldings; `INLINE`/`NOINLINE` | Copy small or annotated definitions to call sites, across modules via interface unfoldings | **have**: `ref-inline`, `ref-inline-single-ref`, `{-# f :: Inline #-}`, and interfaces save simple and inline values (`do-dump-var`).  **Missing:** a size-based heuristic for non-annotated functions (GHC's "unfolding discount" weighing argument shapes), so the libraries need explicit `Inline` (as this round added for IORef, State, MArray) | optimize: `can-inline?`, `optimize-flic-ref-aux` |
| `INLINABLE` | Keep the unfolding for specialization without forcing inlining | **missing** | interface dump; see SPECIALIZE.md |
| Phase control (`INLINE [1]`, rule phases) | Order inlining relative to rewrite rules | **partial**: foldr and build inline at fixed iterations (`*optimize-foldr-iteration*`, `*optimize-build-iteration*`) | optimize |
| Beta reduction | `(\x -> e) a` becomes `let x = a in e` | **have**: `app-lambda-to-let` | optimize |
| Case of known constructor | `case C a of C x -> e` becomes `e[a/x]` | **have**: `sel-fold-app`, `sel-fold-var`, `is-constructor-fold`, and `con-number-fold` | optimize |
| Case of case | Push an outer case into the branches of an inner one, with join points for the outer branches | **missing** in FLIC.  SBCL folds `(if (if …))` but not across constructor dispatch.  It matters after inlining, for example when `maybe`/`either` are inlined over a function returning `Just`/`Nothing` | optimize (a FLIC rewrite on `if`/`case-block` whose test is itself an `if` over constructors), or on LGRIN `case` |
| Binder swap, case merging (`-fcase-merge`), case folding (`-fcase-folding`) | Clean up nested cases on the same scrutinee | **partial**: redundant and duplicate test removal in `case-block` | optimize |
| Let floating (local) | Move `let` out of applications and into `case` branches | **have** (outward): `app-hoist-let`, `case-block-hoist-let`, `let-hoist-lambda`, `foldr-hoist-let` | optimize |
| Eta expansion (`-fdo-lambda-eta-expansion`) and arity analysis | Give a function its full arity, so calls are saturated | **partial**: `app-make-saturated`, `lambda-compress`, `if-hoist-lambda`, and since 2026-10-10 `seq-hoist-lambda`: eta through a bang pattern | optimize |
| The "state hack" | Treat `State# RealWorld` lambdas as one-shot, so eta expansion through `IO` is free | **partial**: the same effect for IO and ST loops via `if-hoist-lambda`/`seq-hoist-lambda`.  There is no one-shot information to make it general | optimize |
| Eta reduction | `\x -> f x` becomes `f` | **missing** (minor; SBCL's code is unaffected) | optimize |
| Known-call saturation of class-method selectors (ClassOp rules) | `op dict` at a known instance becomes the instance's method | **have**: `app-fold-selector` (constant dictionary) and, since 2026-10-10, `app-fold-selector-dictionary-fn` (an instance with a context applied to dictionaries) | optimize |
| Constant folding (`GHC.Core.Opt.ConstantFold`, `-fnum-constant-folding`) | Arithmetic on literals, `x + 0`, comparisons | **partial**: numeric conversions and negation (`magic-optimize-function`), `if-fold`.  Int arithmetic on literals is left to SBCL, which folds it after emission.  GRIN folds `encode-double` | optimize; grin-opt `fold` |
| RULES (user rewrite rules) | `{-# RULES "map/map" … #-}` | **partial**: foldr/build fusion only (`optimize-foldr`, `optimize-build`).  The rules are hard-wired, as are `foldr (:) z l` = `primAppend l z` and the other `foldr-*` identities | optimize, plus a `Rule` annotation (annotation-parser) to make it general |
| Occurrence analysis, dead-code elimination | Count uses; drop unused bindings; find loop breakers | **have**: `var-referenced`, `let-remove-unused-binding`, `case-block-dead-code`.  The comment notes that unused *recursive* bindings are not detected | optimize |
| Simplifier ticks / fuel | Bound the work | **have**: `*max-optimize-iterations*` (5, or 15 with foldr), `record-hack` counts | optimize |

### 2.3 Core-to-Core passes besides the simplifier

| GHC | What it does | Yale status | Place |
|---|---|---|---|
| **Specialise** (`-fspecialise`, `-fcross-module-specialise`, `SPECIALISE`) | Copy an overloaded function for the dictionaries it is called with, recursion included | **missing**; the largest gap the benchmarks show (foldable 7.5×, mapcount 3.5×) | inside optimize, between iterations: **doc/plans/SPECIALIZE.md** |
| Full laziness / float out (`-ffull-laziness`) | Float `let`s out of lambdas so they are computed once (to the top level as CAFs) | **partial**: structured constants (`let-hoist-structured-constant`, `app-hoist-structured-constant`) are floated to the top level.  General float-out is missing.  It can cost space (GHC turns it off with `-fno-full-laziness` for that reason), so float only cheap or constant expressions first | optimize (a separate walk after the first iterations), before strictness |
| Float in (`-ffloat-in`) | Move a `let` into the only branch that uses it, so it is not allocated on the other paths | **missing**.  Box analysis then sees the binding as strict in that branch more often | optimize, a walk before strictness |
| Static argument transformation (`-fstatic-argument-transformation`) | A recursive function's unchanging argument becomes a free variable of a local loop | **have** (Yale did this in 1993): invariant-argument removal (`let-hoist-invariant-args`, `note-invariant-args`), the `dropWhile isSpace` example in Loosemore's note | optimize |
| Liberate case (`-fliberate-case`) | Unroll a recursive function once so that a case on a free variable happens outside the loop | **missing** | optimize |
| SpecConstr (`-fspec-constr`, `-O2`) | Specialise a recursive function for the constructor shapes of its arguments at its recursive calls (no allocation of the `Just`/tuple each iteration) | **missing**.  The candidates are queens (a thunk and a cons per element) and accumulators in tuples | after strictness (it needs to know the argument is evaluated), or in optimize with its own shape analysis; a later step than SPECIALIZE, sharing its copying machinery |
| Exitification (`-fexitification`) | Move a recursive join point's exit code out of the loop | **n/a**: CL `labels` + `return-from` already exit directly | |
| Call arity (`-fcall-arity`) | Eta-expand through `let`-bound functions called with more arguments (foldl via foldr) | **missing**.  It matters for `foldl` written with `foldr` (base's definition); Yale's PreludeModern defines `foldl'` directly | optimize |
| **Demand analysis** (`-fstrictness`) | Strictness, *absence* (unused arguments), usage/cardinality (called once), and CPR | **partial**: strictness of function arguments (Consel's fixpoint over and/or terms, `strictness.mumble`) and local variable boxing (`box.mumble`).  **Missing:** absence, usage (single-entry thunks), nested strictness of fields (`Int` inside a tuple), and CPR | strictness: extend the abstract domain |
| **Worker/wrapper** (`-fworker-wrapper`, `-fmax-worker-args`) | Split a function into a wrapper (unboxes) and a worker (takes unboxed, absent arguments dropped, returns unboxed via CPR) | **partial**: `/OPT` entry points with strict `Int`/`Char`/`Double`/`Float` parameters declared fixnum/double-float (`rep-types`), and `ftype` result declarations.  **Missing:** dropping absent arguments, unboxing fields of strict tuple arguments, and unboxed (multiple-value) returns | grin-lower/grin-emit (the `/OPT` entry and its wrapper), using strictness's results |
| CPR, constructed product result (`-fcpr-anal`) | A function always returning a known constructor returns its fields unboxed instead (`(# a, b #)`) | **missing**; EVAL-APPLY-GRIN.md §5.4 item 3 (CL `values`).  `quotRem`/`divMod`, IO's result, and State's `(a, s)` are the candidates | an analysis on LGRIN, and emission with `values` |
| CSE (`-fcse`) | Common subexpressions | **partial**: structured constants are shared (`*structured-constants-table*`).  General CSE is missing; SBCL does some after emission | optimize |
| Late specialise, late demand analysis (`-flate-specialise`, `-flate-dmd-anal`) | Run them again after the rest | n/a until those passes exist | |
| Unboxing strict fields (`-funbox-small-strict-fields`, default) | `data P = P !Int !Int` stores raw ints | **partial**: strict fields are stored evaluated, and a fixnum in a Lisp vector is already unboxed.  `Double` fields are boxed floats in SBCL; a specialised `(simple-array double-float)` layout for all-`Double` records would unbox them | codegen of constructors (`make-tuple`, `make-tagged-data`); representation types (EVAL-APPLY-GRIN.md §9) |

### 2.4 After Core: STG, Cmm, code generation

| GHC | What it does | Yale status | Place |
|---|---|---|---|
| CorePrep: ANF, saturation of constructors and primops | | **have**: GRIN lowering makes `eval`/`delay` explicit.  Constructors and primitives are saturated in FLIC (`app-make-saturated`) | grin-lower |
| Unarise (unboxed tuples and sums to multiple registers) | | **missing**: needs CPR first.  CL `values` is the target | grin-emit |
| Let-no-escape / join points as jumps | | **have**: `block`/`return-from` and `labels`, and self-calls are local `labels` calls (`self-local`); SBCL compiles them as jumps | grin-emit, SBCL |
| Late lambda lifting (`-fstg-lift-lams`) | Lift closures that would be allocated in loops into top-level functions with extra arguments | **missing**.  SBCL allocates closures for `labels` functions that escape, as `MAKE-FUN` does in profiles; lifting non-escaping ones is SBCL's job and it does it | grin (after lowering) |
| STG CSE (`-fstg-cse`) | | **missing**; minor | |
| Tag inference (GHC ≥ 9.4) | Know that a variable holds an evaluated, tagged value across calls, and skip the enter/eval | **partial**: box analysis ("already evaluated" variables), `inline-eval`, and `speculate`'s all-evaluated test.  **Missing:** across function boundaries; the `/OPT` entry assumes nothing about lazy arguments | strictness/box; grin-opt |
| Pointer tagging | The constructor tag and evaluatedness in the pointer's low bits | **n/a, mostly**: SBCL's lowtags distinguish conses, structs and fixnums.  Enumerations are fixnums, lists are conses, Bool is `t`/`nil`.  A thunk is a cons tagged `%thunk-…`, so `forced?` is one compare | runtime (`src/runtime`) |
| Cmm sinking, common blocks, block layout, shortcutting (`-fcmm-sink`, `-fcmm-elim-common-blocks`, `-fasm-shortcutting`, `-fblock-layout-cfg`) | | **n/a**: SBCL's compiler (constraint propagation, its own block layout) | SBCL |
| Register allocation (`-fregs-graph`), LLVM back end (`-fllvm`) | | **n/a**: SBCL | SBCL; `*code-quality*` sets `speed 3, safety 0` |

### 2.5 Runtime

| GHC | What it does | Yale status | Place |
|---|---|---|---|
| Generational copying GC | | **n/a**: SBCL's gencgc (`--dynamic-space-size`) | |
| **Selector-thunk elimination in the GC** | When the GC finds a thunk `fst p` with `p` evaluated, it replaces it by the field, which fixes a classic space leak (Wadler 1987; Sparud 1993) | **missing**, and SBCL's GC cannot do it.  The tuple-pattern fix of 2026-10-10 removed the worst case (nofib simple), but a lazy pattern binding `let (a, b) = e` still keeps all of `e`'s tuple alive while `a` is unevaluated.  Compile-time alternative: when the tuple is known to be evaluated, select eagerly; speculation already does this for cheap selections, and box analysis could do it for every `sel` of a strict variable | grin-opt (`speculate` on `sel`), box |
| Eager/lazy blackholing | Detect `<<loop>>`, avoid space leaks in long thunks | **have**: `force` blackholes (P1); `blackhole-loop` test | runtime |
| Update avoidance (single-entry thunks) | A thunk entered at most once needs no update | **missing**; needs usage analysis (2.3).  It saves the blackhole bookkeeping (three writes per thunk) | strictness/box, runtime |
| Static INTLIKE/CHARLIKE closures | Small `Int`s and `Char`s are shared | **n/a**: fixnums and characters are immediate in SBCL | |

## 3. What to build, in order

Ordered by what the bench programs and nofib profiles show, cheapest
first within the same value.  Each item should get a switch
(`*grin-optimizations*` style, or a name in `*optimizers*`) and a
bench/RESULTS.md entry.

1. **Specialise**: plan in doc/plans/SPECIALIZE.md; a step in
   `optimize-top`'s iteration loop, before strictness.  Expected:
   foldable 7.5× → ~2×, mapcount 3.5× → ~1.5–2×, all `Data.Map`/`Set`
   code, and mtl code over a polymorphic monad.
2. **Library inlining audit**: mark the small wrappers `Inline`, as this
   round did for `forM_`, `Data.IORef`, State, MArray, `liftA2`.  The
   cheap substitute for a size heuristic.  A size-based
   `can-inline?` for non-recursive functions under N FLIC nodes,
   counting argument shapes as GHC's discounts do, would make most of
   the annotations unnecessary.
3. **Demand analysis upgrades** in strictness.mumble:
   - dictionary parameters strict (`-fdicts-strict`), trivially true;
   - absence: drop unused arguments in `/OPT`;
   - strictness of tuple fields (a strict `(Int, Int)` argument whose
     fields are used strictly).  This feeds item 4.
4. **Worker/wrapper with CPR and unboxed returns** (CL `values`):
   EVAL-APPLY-GRIN.md §5.4 items 3–4.  Expected: State's `(a, s)` pairs
   (statemonad allocates 418 MB), `quotRem`, and `divMod` loops.
5. **Case of case** in FLIC: cheap, and it compounds with inlining
   (`maybe`, `either`, `uncurry`, and `when` over a comparison).
6. **SpecConstr** after Specialise, sharing its copy-and-memo
   machinery: queens and list-comprehension generators.
7. **Float in**, then a conservative **full laziness** (constant
   expressions only), and **CSE**.
8. **Usage analysis and update avoidance**; **eager selection** of
   fields of evaluated tuples (the selector-thunk leak).
9. **General RULES** as an annotation, with the foldr/build identities
   moved into the Prelude as rules.

Not worth doing on this platform: Cmm-level passes, register
allocation, pointer tagging, exitification, and STG CSE.  SBCL and the
Lisp representation cover them.

## 4. How to tell a pass is worth keeping

- `bench/compare-ghc -n 3` before and after: the ratio column, and the
  allocation column ("Yale MB"), which does not depend on machine load.
- `YALE_HASKELL_PROFILE=1 bin/yale-haskell …` for where the time goes;
  `bin/yale-haskell compile F --emit optimize,grin,lisp` for what the
  pass did.
- `make test`, `tools/conformance/extensions.py` and
  `tools/conformance/nofib.py` for correctness (nofib 68 at this
  writing); and compile time (`YALE_HASKELL_TIME=1` prints it).
