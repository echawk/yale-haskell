# SPECIALIZE: copies of overloaded functions for known dictionaries

Status: planned (2026-10-10).

## Why

Overloaded code takes its class dictionaries as arguments.  The
optimizer already removes the dictionary when it can see it:

- a method selected from a constant dictionary (`sel-Show/show
  dict-Show-Int`) folds to the instance's method (`try-to-fold-selector`
  in `src/compiler/backend/optimize.mumble`);
- since 2026-10-10, a method selected from a dictionary *function*
  applied to dictionaries (`sel-Monad/>>= (dict-Monad-StateT
  dict-Monad-Identity)`, also through a local `let`) folds to the
  instance method applied to them (`dictionary-fn-field`), and
  interfaces keep dictionary functions' values for this;
- an `Inline` function or instance method is copied into its caller,
  where its dictionary arguments become constants.

What it cannot do is a **recursive** overloaded function, which is never
inlined.  Inside it the dictionary stays a parameter, so every method
call is a selection plus an unknown call, every `>>=` or `<*>` builds
closures, and nothing inlines.  GHC handles this with its specializer
(automatic for local and `INLINABLE` functions, and the `SPECIALISE`
pragma).  The bench programs show the cost (bench/RESULTS.md,
2026-10-10):

| program | Yale | GHC -O2 | where the time goes |
|---|---|---|---|
| foldable (`traverse` in `Maybe` over a derived `Traversable`) | 1.9 s | 0.23 s | `i-Traversable-Rose-traverse d_Applicative`: recursive, so `pure`/`<*>`/`liftA2` stay dictionary calls; 1.4 s of the 1.9 |
| statemonad (strict `State`) | 0.17 s | 0.025 s | solved for non-recursive code by dictionary-function folding; a recursive `StateT` helper polymorphic in the monad would hit the same wall |
| mapcount (`Data.Map` with `Int` keys) | 1.1 s | 0.34 s | `insertWith`, `lookup` etc. are recursive and take `Ord k`: every comparison is `sel-Ord/compare d_Ord` |

The same pattern is in every `Data.Map`/`Set` operation, in derived
`Foldable`/`Traversable` instances, in `mapM`/`foldM` over a monad given
by a dictionary, and in mtl code written against `MonadState s m`.

## The transformation

For a call `f e1 ... ek a1 ... an` where `f` is a top-level function
whose first k parameters are dictionary parameters and `e1 ... ek` are
*constant dictionary expressions* (a top-level dictionary variable, or
a dictionary function applied to constant dictionary expressions):

1. Look up `(f, e1 ... ek)` in a per-module memo table.  If absent,
   create a new top-level variable `f@spec<n>` bound to a copy of `f`'s
   value (a `flic-lambda`) with its first k parameters bound to
   `e1 ... ek` (`do-lambda-to-let-aux`, as selector folding does), and
   record it **before** walking the copy, so that
2. a recursive call inside the copy with the same dictionary arguments
   (`f d1 ... dk ...` where each `di` is the copy's own parameter, now
   bound to `ei`) becomes a call of `f@spec<n>`.  This is what makes the
   specialization close over the recursion instead of unrolling it once.
3. Replace the call with `f@spec<n> a1 ... an`.

After this, the optimizer's existing rules do the rest: selections from
`ei` fold to instance methods, `Inline` methods inline, and the
strictness pass and GRIN see first-order code.

Recognizing dictionary parameters: cfn adds them from
`valdef-dictionary-args` (`src/compiler/cfn/pattern.mumble`); they are
the leading lambda vars named `d_<Class>`.  A flag on the var set there
is better than matching names; that is part of step 1 below.

## Where it goes in the pipeline

The phases (`compile-modules`, `src/compiler/top/phases.mumble`):

```
import-export  type-decls  scope  depend  type  cfn  depend2
  ast-to-flic  optimize  strictness  codegen (GRIN or the old back end)
```

SPECIALIZE belongs **inside `optimize`**, as a step of the optimizer's
iteration loop (`optimize-top`), not as a separate phase:

- **After at least one optimizer iteration.**  Constant dictionaries
  only appear at call sites after inlining and selector folding have
  run (for example, `forM_` inlined at its use exposes `mapM_`'s
  `Foldable []` and `Monad IO` dictionaries).  So the step runs at a
  fixed iteration, as the foldr/build steps do
  (`*optimize-build-iteration*`, `*optimize-foldr-iteration*`), say
  iteration 1, and again at a later one for dictionaries exposed by the
  first round.
- **Before the last iterations.**  The new `f@spec` bindings need
  further optimizer passes for their selections to fold and their
  methods to inline.  New top-level bindings are added to the module's
  big `let` the way structured constants are (`*structured-constants*`,
  appended at the end of `optimize-top`); the specialized ones must
  instead join the bindings walked by the remaining iterations.
- **Before `strictness`.**  The strictness analysis needs the
  first-order code: a specialized `foldr`-like loop over `Int` becomes
  strict in its accumulator, which it is not while `+` is
  `sel-Num/+ d_Num`.  GRIN's representation types (fixnum parameters)
  follow from that.

The rough shape inside `optimize-top`:

```
(dotimes (i max-iterations)
  (optimize-flic-let-aux object '#t)          ; existing
  (when (memv i *specialize-iterations*)      ; new, e.g. (1 3)
    (specialize-calls object)))               ; adds f@spec bindings
```

## Across modules

Most targets are defined in another module than the call (`Data.Map`'s
`insert`, a derived instance's `traverse` in the Prelude or a library).
The copy needs `f`'s FLIC value, which interfaces keep only for simple
and `Inline` variables (`do-dump-var` in
`src/compiler/csys/dump-interface.mumble`; dictionary functions were
added on 2026-10-10).  Two options:

1. A `Specialize` annotation (`{-# insert :: Specialize #-}`, parsed like
   `Inline` in `src/compiler/parser/annotation-parser.mumble`) that saves
   the value in the interface.  The library marks the functions worth
   it: `Data.Map`/`Set` operations, `mapM`/`foldM`/`traverse` and the
   derived `Foldable`/`Traversable`/`Functor` methods.  This is GHC's
   `INLINABLE`.
2. Save the value of every overloaded function below a size limit.
   This is simpler for users but makes interfaces larger.

Start with 1.  The specialized copies live in the module that uses
them; the memo table removes duplicates within a module, but not across
modules.  A copy shared through the defining module would need its
dictionaries to be known there, which they are not.

The unit cache needs no change: a cached unit already records the units
it imports (`<cfile>.imports`) and is rebuilt when one is newer, and a
specialized copy depends only on what the interface it was copied from
says.

## Steps

1. Mark dictionary parameters on their vars in cfn (or ast-to-flic), and
   add `dictionary-params f` returning the count.
2. `specialize-calls`: the walk, the memo table, the recursive-call
   rewrite, and adding the bindings; one module only (no interface
   change).  Test: a local recursive `Ord a => ...` function called at
   `Int`, checking with `--emit optimize` that no `sel-Ord` remains.
3. The `Specialize` annotation and its interface dump; mark the library
   functions above.
4. Measure: foldable, mapcount and statemonad in `bench/compare-ghc`, and
   nofib for regressions and compile time (copies add code; give each
   module a budget, for example at most 50 specializations, and record
   that in a hack count, as `record-hack` does).

Done when foldable's `traverse` and mapcount's `insertWith` run without
dictionary selections, and the bench table records it.
