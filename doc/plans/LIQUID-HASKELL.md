# Plan: refinement types in the style of LiquidHaskell

Status: milestone 1 (the typed core) done, 2026-10-17; milestone 2
(checking with Z3) done, 2026-10-19: `--liquid` checks a module's
top-level functions against the `{-@ @-}` signatures, type aliases and
`assume`s in its source (src/compiler/liquid/core.mumble converts cfn's
typed output to the small language of src/liquid/check.lisp, which asks
Z3 about each obligation), for Int and Bool arithmetic, comparisons,
calls, `if` and `let`; anything else is an unconstrained value.  An
unproved obligation is a compile error at its binding's line.  Tests in
tests/haskell98/liquid/.  Milestone 3 (inference) done, 2026-10-19:
functions without a signature get templates with kvars (local
functions' parameters and results, top-level functions' results),
solved together by src/liquid/fixpoint.lisp over the default
qualifiers and the atoms of the written refinements; `qualif`
declarations are not read yet.  Milestone 4 (lists and measures) done,
2026-10-19: `len`, the module's own `measure`s over lists, facts from
list constructors and pattern matches, and specifications for the
Prelude's list functions (head, tail, !!, length, null, ++, take, drop,
replicate, map, reverse, filter); refined `data`, measures over other
data types and `inline` are not done yet.  Milestone 5 (polymorphism and
higher-order functions) done, 2026-10-19: refined instantiation of type
variables at calls (not of list element types, which are untracked),
lambdas and function names checked against refined function types,
function-typed parameters, foldr, foldl, zipWith and zip, and Array's
listArray and (!) at Int indexes (measures alo and ahi).  Milestone 6
(termination) done, 2026-10-19: each self-recursive call must decrease a
metric that is non-negative at the caller: the signature's `/ [..]`
(lexicographic), else the first that works of an Int parameter, a list
parameter's `len`, and the difference of an Int parameter and an Int
binder in scope; `lazy` turns the check off.  The rest is design.

Known limits of milestones 2-6, to be lifted later:
- **Error reports.** An error is reported at the line of the function it
  is in, not of the expression (cfn's nodes mostly have no source
  positions), and its message names the checker's own variables
  (`lq_t6`, `lq_p1`) and cfn's (`ARG9055`) instead of `v` and the
  source's names.
- **Qualifiers.** `qualif` declarations are not read; the qualifiers
  are the defaults (comparisons with 0, with the binders in scope and
  with `len`) and the atoms of the written refinements, whose free
  variables are taken to be Int unless they are a measure's argument.
- **Signatures.** Local functions (`where`, `let`) cannot have
  signatures; their refinements are always inferred.  In a function
  parameter's refined type, the binders of the function's earlier
  parameters are not substituted.
- **Data types.** Only lists have measures and pattern-match facts:
  `case` on other data types, tuples, refined `data` declarations,
  measures over other types and `inline` are not supported (their values
  are unconstrained).  A measure whose `(:)` equation uses the head is
  ignored.
- **List elements** carry no refinements, so a type variable that is a
  list's element type (`head`, `map`, `foldr`'s `a`) is not refined at a
  call, and `[{v:Int | v > 0}]` means nothing.
- **Higher-order code.** A function without a signature that is used as
  a value (not called) gets unrefined parameters; a function-typed
  parameter of such a function is unrefined; an argument that is
  neither a lambda nor a function's name is opaque.
- **Library.** Specifications exist only for the Prelude list functions
  above, `foldr`, `foldl`, `zipWith`, `zip`, and Array's `listArray` and
  `(!)` with Int indexes (not `bounds`, `array`, `//`, or other index
  types); other library functions are unconstrained.
- **Termination.** Only a function's calls of itself are checked:
  mutual recursion (between top-level functions, or local functions of
  one group) and recursive values with no parameters (`ones = 1 : ones`)
  are assumed to terminate.  Without a written metric only the default
  candidates above are tried (no `n - i + 1`, no sums).  `data size`,
  `autosize` and `lazyvar` are not supported, and a recursive function
  passed as a value is not checked at the calls through it.

The aim is a refinement type checker inside Yale Haskell that accepts
LiquidHaskell's specification language (`{-@ ... @-}` comments), checks
Yale programs against it with an SMT solver, and infers refinements
where none are written.  This is not "run LiquidHaskell".  The plan
reimplements the method on Yale's own intermediate form.

Sources:
- P. Rondon, M. Kawaguchi, R. Jhala, "Liquid Types", PLDI 2008: the
  inference algorithm (templates, qualifiers, predicate abstraction).
- N. Vazou, E. Seidel, R. Jhala, D. Vytiniotis, S. Peyton Jones,
  "Refinement Types for Haskell", ICFP 2014: soundness under lazy
  evaluation (stratified types, termination).
- N. Vazou, P. Rondon, R. Jhala, "Abstract Refinement Types", ESOP
  2013.
- N. Vazou et al., "Refinement Reflection", POPL 2018 (`reflect`, PLE).
- LiquidHaskell's documentation, "Specifications" page: the `{-@ @-}`
  syntax listed in section 3.
- The `liquid-fixpoint` package (BSD-3): the Horn-constraint solver
  that LiquidHaskell uses, as a reference and a possible external
  solver.

## 1. Why not run LiquidHaskell itself

LiquidHaskell is a GHC plugin.  It works on GHC Core after
desugaring, takes names and types from GHC's API, and its
specifications for the libraries (`M_LHAssumptions` modules,
e.g. `GHC.Base_LHAssumptions`) describe GHC's `base`.  Running it
under Yale would mean compiling the `ghc` package.  Its method is
independent of GHC, though, and is published in detail:

1. Turn refinement specifications into refined types.
2. Generate subtyping constraints over a typed core language.
3. Solve them: verification conditions go to an SMT solver, and unknown
   refinements are inferred as conjunctions of qualifiers by fixpoint
   iteration.

All three can be done on Yale's representation.

## 2. Where it goes in Yale's pipeline

The checker needs a small, typed, desugared language: every variable
and every subexpression with its Haskell type, patterns compiled to
simple cases, and dictionaries explicit.  Yale is close to having one.

- **After type checking**, only variables keep types (`var-type`, a
  `gtype`, in `src/compiler/ast/definitions.mumble`).
  - Expression nodes have no type slot (`exp` in
    `ast/exp-structs.mumble`).
  - The types inferred for them (`src/compiler/type/`) are computed
    during unification and not stored.
  - In particular, the type at which a polymorphic variable is used is
    not stored.
- **The cfn phase** (`src/compiler/cfn/`) turns the checked AST into a
  small language (`cfn/README`): `lambda`, `let`, `if`, `case` on
  literals or on a constructor with variable arguments, `app`,
  `var-ref`, `con-ref`, `const`, `con-number`, `sel`, `is-constructor`.
  - Lists, sequences, comprehensions, sections, guards and `where`
    are gone.
  - Dictionaries are explicit arguments, from the type checker's
    dictionary conversion.
  - This is the right language to check, with types added.
- **After cfn**, the FLIC conversion and the optimizer drop types
  entirely.  The checker must run before them.

So the checker is a new phase between `haskell-cfn` and
`haskell-dependency-reanalysis` in `compile-modules`
(`src/compiler/top/phases.mumble`).  It reads cfn's output, does not
change it, and fails the compilation (or warns, per a flag) when a
constraint is unsafe.  The rest of the pipeline is unchanged.

### 2.1 The typed core (the gate for everything else)

**Done (2026-10-17), differently from the steps below.**
- **What was built:**
  - Every expression keeps the type inference gave it
    (`exp-inferred-type`, recorded in one place, `dispatch-type-check`).
  - A typed phase after cfn (`src/compiler/typed/retype.mumble`) types
    cfn's output again by unification over that small language.  The
    let-bound variables' `var-type`s are known, so no generalization
    is needed, and the compiler's own types are copied, never bound.
  - It runs only for `--emit typed` (which prints each top-level
    binding's type) or `YALE_HASKELL_TYPED_CENSUS=1` (its coverage
    report), and changes nothing.
  - `tools/typed-core.py` measures it over the test programs.
- **How dictionaries are typed:**
  - A dictionary's type is `C t`, an ntycon whose tycon is the class.
  - Variables take one dictionary per class per type variable, then the
    multi-parameter ones; a method of a multi-parameter class takes its
    own class's first.
  - A method selector `sel-C/S.m` takes `C`'s dictionary in the
    method's place.
  - Constructors take none for a datatype context, but an existential
    constructor's dictionaries are its fields.
- **Representation boundaries.** Three places in generated code treat
  a value as its representation, and the unifier accepts them:
  - a dictionary's own definition is a tuple of its methods (typed, not
    checked against its rough `var-type`);
  - a newtype is its field (cfn erases the constructor);
  - an enumeration is its `Int` tag (derived `Enum`).
- **Result over the test programs:** 99.68% of 273,544 expressions get
  a type, and 99.93% of the 118,216 that inference also typed agree.
  - The failures are in GADTs, rank-N contexts and type families, which
    the type checker itself only approximates (GHC-EXTENSIONS.md) and
    which section 7 says the checker should skip.
  - The other residue is the record selector of a newtype over a monad
    transformer, where `m x ~ WriterT w m' a` reads both as an
    instance and as the erased field.
  - Over LambdaPi, cubicaltt and happy with all their libraries,
    99.8% of expressions get a type.
- **For optimization it does not reach far yet.** The optimizer's hot
  loops (the `iterate'` and `foldr'` of fusion, and other inlined
  Prelude code) are made after this phase, from interface code that
  carries no types.  A type-directed declaration pass (unboxed `Double`
  parameters across calls) would need types kept on FLIC variables
  through `copy-flic` and the interfaces (`dump-flic`).  For `Int`
  nothing is lost today: the primitives already expand to `(the fixnum
  ...)`, and SBCL infers through `let`.

The plan as first written:

1. **Record instantiations during type checking.** At each `var-ref`
   and `con-ref`, store the type the variable is used at (the
   instantiated `ntype`) in a new slot.  It is resolved after
   unification: pruned `ntyvar`s, `ntycon`s.  Also store each
   literal's type.

   Files:
   - `type/type-vars.mumble` (`type-check-var-ref`);
   - `type/expression-typechecking.mumble`;
   - the slots in `ast/exp-structs.mumble`.

   Defaulting (`type/default.mumble`) must update the stored types it
   fixes.
2. **Keep them through cfn.** cfn copies `var-ref`s and builds new
   nodes:
   - `sel`, `is-constructor` and `con-number` from patterns;
   - `if` from guards;
   - `let` from `where`.

   The new nodes' types follow from their parts (`sel`'s from the
   constructor's field type at the instance), so a retyping pass over
   cfn's output can compute every node's type bottom-up, given the
   stored `var-ref` types and the `var-type` of binders.  That pass is
   a new file, `src/compiler/liquid/retype.mumble`.
3. **A printer**, so the typed core can be inspected: an `--emit typed`
   stage in `src/compiler/command-interface/batch.mumble`
   (`*emit-stages*`) and a printer in `src/compiler/printers/`.

This step is useful on its own, as a check of the type checker
(retyping must agree with inference) and for later optimizations that
want types (unboxing, worker/wrapper).

## 3. Specifications

### 3.1 Syntax

LiquidHaskell writes specifications in `{-@ ... @-}` block comments.
Today the lexer drops them as comments.  It must capture them when the
checker is on (a `--liquid` flag, or `{-# LANGUAGE ... #-}`-like
opt-in).  They are parsed by a separate grammar, in
`src/compiler/liquid/spec-parser.mumble`, reusing the type parser
(`parser/type-parser.mumble`) for the Haskell types inside.

Forms, in the order to support them (from LiquidHaskell's
"Specifications" page):

| Form | Example | Milestone |
|---|---|---|
| refined signature | `{-@ incr :: x:{v:Int \| v > 0} -> {v:Int \| v > x} @-}` | 2 |
| type alias, with value parameters | `{-@ type Gt N = {v:Int \| N < v} @-}` | 2 |
| `assume` | trusted signature (library primitives) | 2 |
| `qualif` | `{-@ qualif Foo(v:Int, a:Int) { v = a + 100 } @-}` | 3 |
| `measure` | `{-@ measure len :: [a] -> Int @-}` and the Haskell-function form `{-@ measure llen @-}` | 4 |
| refined `data` | fields with refinements, e.g. `elems :: {v:[a] \| len v = size}` | 4 |
| `inline` | a non-recursive Haskell function usable in refinements | 4 |
| termination metrics | `/ [len xs]`, lexicographic `/ [m, n]`, `lazy`, `data size` | 6 |
| `reflect`, PLE | recursive functions in the logic | later |
| abstract refinements, `data variance`, `using`, class measures | `<p :: a -> Bool>` | later |

### 3.2 The logic

Refinement predicates use:
- linear integer arithmetic (`+`, `-`, multiplication by constants);
- comparisons, `&&`, `||`, `not`, `=>`, `<=>`;
- `if-then-else`;
- equality on any sort;
- uninterpreted functions for measures.

This is the SMT-LIB2 fragment QF_UFLIA, plus algebraic data types when
measures are inlined.  Sorts:
- `Int`, `Integer`, `Char` (as Int) and `Bool` map to the SMT sorts;
- other Haskell types are uninterpreted sorts named by their type
  constructor.

### 3.3 Library specifications

Yale owns its Prelude and libraries (`lib/haskell98/`), which makes
this simpler than for LiquidHaskell, whose specifications sit outside
GHC's `base`.  Two options:

- **Put them in the library source** as `{-@ @-}` comments next to the
  definitions.  `head :: {v:[a] | len v > 0} -> a` sits by `head`.
  This is simplest, and the specifications are checked when the
  library is compiled with the checker on.
- **Use LiquidHaskell's convention**: a module `M_LHAssumptions`
  holding `assume` specifications for module `M`, loaded when `M` is
  imported.  This is needed only to reuse LiquidHaskell's own
  specification files (BSD).

Start with the first.  The specifications go into the module interface
(`csys/dump-interface.mumble`) so that importing modules see them
without recompiling.

## 4. Constraint generation

New `src/compiler/liquid/constraints.mumble`, over the typed core, as
in "Liquid Types" and LiquidHaskell's `Constraint` modules:

- **Templates.** Each binder without a specification gets a refined
  type whose refinements are unknowns (κ variables), the Haskell type
  being the shape.
- **Judgments.** The environment holds the binders with their refined
  types, plus guards (path conditions from `if` and `case`).
  - `app` checks the argument against the function's domain,
    instantiating dependent arrows: `x:{v:Int | v > 0} -> ...` with
    the argument for `x`.
  - `let` gives the binder its template and checks the body.
  - `case` and `is-constructor` add measure facts for the branch:
    `len xs > 0` in the `(:)` branch.
  - `sel` gives the field's refinement.
  - Constants get singleton refinements (`v = 5`).
  - Each primitive gets an `assume` type:
    `primPlusInt :: x:Int -> y:Int -> {v:Int | v = x + y}`.
- **Subtyping.** `{v:B | p} <: {v:B | q}` in environment Γ is the
  implication (Γ ∧ p) ⇒ q.  Function subtyping is contravariant, and
  the type constructors follow their variance.
- **Well-formedness.** Each κ may mention only the binders in scope at
  its template.  This decides which qualifier instances are candidates.
- **Polymorphism.** A type variable instantiated at a use site gets a
  fresh template (LiquidHaskell's refined instantiation), so
  `map (+1) xs` can carry refinements through `map`.  This comes after
  the first-order milestones.
- **Dictionaries.** Explicit dictionary arguments are trusted: their
  methods get the class method's `assume` type (unrefined, at first).
- **Laziness.** A binder's refinement only holds once it is evaluated.
  In a lazy language a diverging binder can make an assumption false
  (the ICFP 2014 paper's point).  LiquidHaskell's answer:
  - termination checking (metrics) for recursive functions;
  - for non-terminating code, `lazy`.

  Until termination checking exists (milestone 6), the checker should
  say in its output that results assume termination, as LiquidHaskell
  does with `--no-termination`.
- **Source positions.** Each constraint keeps the source location of
  the node that made it.  cfn's nodes keep their positions (check this:
  some are created without any).  An unsafe constraint is reported at
  that location, with the two refinements involved.

## 5. Solving

### 5.1 Without inference: Z3 alone

When every binder that matters has a specification (and there are
no κ variables), each constraint is a closed implication.  Write it in
SMT-LIB2 and ask Z3 whether its negation is satisfiable: `unsat` means
safe.  Z3 is installed here (`/opt/homebrew/bin/z3`, version 5.1.0).

Run it as a subprocess, with one process per module and `(push)` and
`(pop)` per constraint, using the process primitives System.Process
already has (`prim.launch-process` in `src/base/base-runtime.lisp`).
This milestone needs no fixpoint solver and checks fully annotated
code, which is already useful.

### 5.2 With inference: the fixpoint solver

Unknown refinements (κ) are solved by predicate abstraction:
1. Start each κ at the conjunction of all qualifier instances
   well-formed for it.
2. Repeatedly remove the conjuncts that some constraint falsifies,
   each removal checked by an SMT validity query, until every
   constraint holds or one with a concrete right-hand side fails.

This is "Liquid Types" section 4.  Two ways to have a solver:

- **Use liquid-fixpoint's `fixpoint`**, built with GHC.
  - Emit its Horn input format (SMT-LIB-like, examples in its
    `tests/horn`), run `fixpoint --stdin --json`, and read the
    `Safe`/`Unsafe` result.
  - It is not installed here, and building it means installing a
    Hackage package with GHC: network, dependencies, and GHC-version
    bounds.
  - Its input format is an interface that changes between versions,
    so pin the version.
- **Write the solver in Lisp**, in `src/compiler/liquid/fixpoint.mumble`:
  qualifier instantiation, iterative weakening, and Z3 for each
  implication check.
  - The algorithm is a few hundred lines.  It keeps Yale
    self-contained and avoids a GHC-built dependency.
  - Its weakness is performance.  liquid-fixpoint has years of tuning:
    constraint partitioning, elimination of κs that have a single
    definition, and incremental SMT.  Real code may need those.

Recommendation: write the simple solver in Lisp first.  It is enough
for the first milestones' tests, and it makes the format of the
constraints Yale's own choice.  Keep liquid-fixpoint's Horn format as
an export (`--emit horn`), so the two solvers can be compared, and
switch to liquid-fixpoint if programs outgrow the simple one.  Once
packages build through MicroCabal (MICROCABAL.md step 5),
liquid-fixpoint could even be compiled by Yale itself.

### 5.3 Qualifiers

The defaults, as in LiquidHaskell:
- comparisons of `v` with 0, with the binders in scope, and with
  measures of them (`v < len xs`);
- the qualifiers found in the specifications themselves (every atom of
  a written refinement becomes a qualifier, which LiquidHaskell does
  too);
- `qualif` declarations.

## 6. Milestones

Each one gets tests in a new `tests/haskell98/liquid/` directory,
written as pairs: a program that must check (`SAFE`) and one that must
fail at a given line (`UNSAFE`), with the expected output in `.stdout`
and the exit status in `.exit`.  Where LiquidHaskell's own test suite
(`tests/pos`, `tests/neg`, BSD) has a program in the supported subset,
use it, the way nofib is used for conformance.

1. **Typed core.** Stored instantiations, retyping of cfn output,
   `--emit typed`.
   - Test: every node of every test program and of the Prelude gets a
     type, and retyping agrees with inference.
   - No refinements yet.
2. **Checking with Z3, first-order Int and Bool.** Refined signatures,
   aliases, `assume`; constraint generation for `lambda`, `app`, `let`,
   `if`; primitives with `assume` types; Z3 per constraint.
   - Test: `abs`, `max`, a safe division `div :: Int -> {v:Int | v /= 0}
     -> Int` with callers that are safe and unsafe, and a counter that
     stays non-negative.
3. **Inference.** Templates and κs, the Lisp fixpoint solver,
   qualifiers, `qualif`.
   - Test: local functions and recursive loops with no specification,
     whose refinements are inferred: a `sum` loop's accumulator stays
     `>= 0`, and an index stays within `0 .. n-1`.
4. **Data types and measures.** `measure len`, refined `data`, `case`
   facts, `inline`; specifications for the list functions in the
   Prelude: `head`, `tail`, `!!`, `length`, `++`, `take`, `replicate`.
   - Test: `head` only on non-empty lists, `xs !! i` with `i < len
     xs`, a list-length-preserving `map`.
5. **Polymorphism and higher-order functions.** Refined instantiation
   of type variables.  Specifications for `map`, `foldr`, `zipWith`;
   arrays (`Data.Array` bounds: `!` with an index in bounds).
6. **Termination.** Default metrics (the first `Int` or sized
   argument), explicit `/ [..]`, `lazy`, `data size`, `autosize`.
   Soundness of milestones 2-5 under laziness rests on this.
7. **Type classes.** Refined class methods, instance checking, class
   measures.
8. **Later:** abstract refinements, refinement reflection and PLE,
   `using`, `relational`.  These are research-grade even in
   LiquidHaskell; take them up only with a program that needs them.

## 7. Pain points

1. **Types after type checking.** Everything depends on milestone 1.
   The type checker was not written to leave types behind, and its
   unification variables are pruned lazily, so the stored types must be
   resolved at the end of each binding group.  cfn's restructuring
   (pattern-match compilation, guards to `if`, `where` to `let`) must
   keep or recompute every node's type.  Any node without a type is a
   hole the checker cannot see through.
2. **Positions.** Error messages must point at source lines, but cfn
   and the dictionary conversion create nodes that may lack positions.
   Audit and fix while doing milestone 1.
3. **Laziness and soundness.** A refinement on a binder is an
   assumption that holds only if the binder evaluates.  Without
   termination checking (milestone 6), checking is sound only for code
   that terminates.  Say so in the output until then.
4. **The size of the specification language.** LiquidHaskell's surface
   is large (section 3.1's table and more).  Accept the subset, and
   report "not supported" for the rest, rather than misreading it.
5. **The solver.** A naive fixpoint solver can be slow on real code:
   many κs, many qualifier instances, one Z3 query each.  Mitigations,
   in order:
   - batch queries in one Z3 process;
   - eliminate κs with a single definition, as liquid-fixpoint does;
   - partition independent constraints;
   - fall back to liquid-fixpoint.
6. **Library specifications.** Useful checking needs specifications
   for most of the Prelude, Data.List, Data.Map, Data.Array and the
   numeric classes.  That is steady writing, not design, but it is
   most of the work after milestone 5.
7. **Dictionaries and classes.** cfn's output passes dictionaries
   explicitly, and method calls are selections from them.  Until
   milestone 7, they are opaque: a call through a dictionary is
   checked only against the unrefined method type.
8. **Interaction with other features.** GADTs, type families and
   existentials (all approximated in Yale's type checker, per
   GHC-EXTENSIONS.md) have no refinement story here.  The checker
   should skip definitions that use them, with a note, rather than
   reason about them.

## 8. File checklist

| Area | Files |
|---|---|
| Typed core | `src/compiler/ast/exp-structs.mumble` (instantiated-type slots on `var-ref`, `con-ref`, constants); `src/compiler/type/type-vars.mumble`, `expression-typechecking.mumble`, `default.mumble` (record and resolve them); `src/compiler/cfn/*.mumble` (keep them); new `src/compiler/liquid/retype.mumble` |
| Phase | `src/compiler/top/phases.mumble` (`haskell-liquid` between `haskell-cfn` and `haskell-dependency-reanalysis`, behind a flag); a unit file for `src/compiler/liquid/` in the compiler's unit list |
| Specifications | `src/compiler/parser/lexer.mumble` (keep `{-@ @-}` blocks when the checker is on); new `src/compiler/liquid/spec-parser.mumble`, `spec.mumble` (refined types, aliases, measures, qualifiers); `src/compiler/csys/dump-interface.mumble` (specifications in interfaces) |
| Checking | new `src/compiler/liquid/constraints.mumble` (templates, constraint generation), `fixpoint.mumble` (qualifiers, iterative weakening), `smt.mumble` (SMT-LIB2 output, the Z3 process, results), `report.mumble` (errors with locations) |
| Runtime | `src/base/base-runtime.lisp` (a persistent subprocess with line I/O, if the process primitives are not enough for an interactive Z3 session) |
| CLI | `src/cli/cli.lisp` and `src/compiler/command-interface/batch.mumble` (`--liquid`, `--emit typed`, `--emit horn`, `--emit smt`) |
| Library specs | `lib/haskell98/prelude/*.hs`, `lib/haskell98/List.hs`, `Data/Array/*.hs`, `Data/Map*.hs` (`{-@ @-}` specifications beside the definitions) |
| Tests | new `tests/haskell98/liquid/` (pos and neg pairs); possibly a harness `tools/conformance/liquid.py` running the supported subset of LiquidHaskell's own tests against their expected verdicts |
| Docs | this file; README (the flag); GHC-EXTENSIONS.md (a row for refinement types) |

## 9. Order relative to other plans

Milestone 1 (the typed core) is worth doing first and on its own: it
tests the type checker and gives later optimizations the types they
lack.  Milestones 2-4 give a useful checker for first-order code with
lists.  The full LiquidHaskell experience (polymorphism, classes,
reflection, the library specifications) is a long project.  It ranks
after the MicroCabal backend (MICROCABAL.md step 5) and Template
Haskell (TEMPLATE-HASKELL.md), which unblock more real code.
