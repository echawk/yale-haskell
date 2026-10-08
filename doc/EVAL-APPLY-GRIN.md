# Eval/apply and a GRIN-style back end — implementation guide

This guide covers two changes to the back end, and how each maps onto
Common Lisp:

- moving Yale Haskell to the **eval/apply** calling convention;
- adding a **GRIN-style intermediate language** between the existing
  FLIC optimizer and Lisp code generation.

It is written for agents (human or LLM) implementing the change, in the
style of [STRATEGY.md](STRATEGY.md).  Background reading is listed in
[GEMINI-NOTES.md](GEMINI-NOTES.md) and in §12.

**Priority.** Haskell 98 conformance comes first (STRATEGY.md M6–M9).
Nothing here should start before records and qualified names land,
except §10 P0 (benchmarks) and P1 (thunk representation).  Front-end work
must not block on this, and this work must not change front-end
behaviour.

---

## 1. Where the back end is today

These facts are verified against the source; section numbers in brackets
refer to the survey these notes came from.

| Aspect | Today | Where |
|---|---|---|
| IR after type checking | **FLIC**: untyped, first-order-ish tree.  Nodes: `lambda`, `let` (rec), `app` (with `saturated?`), `ref`, `const`, `pack`, `case-block`/`return-from`/`and`/`if`, `sel`, `is-constructor`, `con-number`, `void`.  There is no `case` node; pattern matching is `block` + `and` + tests | `flic/flic-structs.mumble` |
| Unit of compilation | A whole module is one big `letrec`; optimizer, strictness and codegen run on it | `top/phases.mumble:65-85, 207` |
| Optimizer | Inlining, beta, dead code, selector folding (removes dictionary lookups), foldr/build, case-block simplification.  `postoptimize` sets `var-arity` and `saturated?` | `backend/optimize.mumble` |
| Strictness | First-order, per-function boolean argument strictness (Consel); results in `var-strictness`, `var-strict?`, `con-slot-strict?`; `.hi` pragmas `Strictness("S,N")` | `backend/strictness.mumble` |
| Boxing | Decides for each expression whether it is forced, boxed or delayed (`unboxed?`, `cheap?`, `strict-result?`) | `backend/box.mumble`, table at `codegen.mumble:62-79` |
| Thunk | Mutable **cons** `(flag . closure-or-value)`; `force` updates in place; no blackholing; the closure is kept after update (a leak) | `runtime/runtime-utils.mumble:16-62` |
| Function value | `make-curried-fn`: a `(lambda args ...)` closure over `&rest`; arity is implied by the captured strictness list; partial applications are new closures | `runtime-utils.mumble:77-119` |
| Known saturated call | Direct call of the `|M:f/OPT|` defun (args boxed or raw per callee strictness) — already "direct entry" | `codegen.mumble:258-281` |
| Unknown call | `(funcall f boxed-args…)` → `&rest` consing → `apply` | `codegen.mumble`, `runtime-utils.mumble` |
| Data | `[]`=`nil`, `:`=cons, Bool=`t`/`nil`, enums=fixnum tag, single-constructor types untagged (field / cons / vector), sums=`(vector tag f1…)`; fields boxed unless strict | `runtime-utils.mumble`, `codegen.mumble:283-363` |
| Dispatch | Nested `(block (and (eqv tag k) …) …)`; no jump tables | `codegen.mumble:391-464` |
| Types in back end | **None** — `var-type` exists but codegen ignores it | |
| Tail calls | Left to SBCL; a `force`/`delay` wrapper breaks tail position | |
| Cross-module info | `-hci` interface files carry `arity`, `strictness`, the `/OPT` entry name, and inlinable FLIC bodies | `csys/dump-interface.mumble:625-690` |

What is already good and must be kept:

- the direct `/OPT` entry for known saturated calls;
- strictness-driven passing of raw arguments;
- dictionary selection folding;
- readable `|Module:name|` symbols.

What blocks performance:

- every unknown call conses an argument list and goes through `apply`;
- thunks and data cannot be told apart at runtime, so nothing can ask
  "is this evaluated?" without static knowledge;
- there is no blackholing, and evaluated thunks leak their closures;
- dispatch is linear;
- nullary non-enum constructors allocate on every use;
- types are not used, so `Int` and `Double` are never unboxed.

---

## 2. Design goals and constraints

1. **Keep the architecture.**  The front end, FLIC, the optimizer and
   strictness analysis stay.  The new IR is inserted *after*
   strictness/box analysis and *replaces codegen*.  The pipeline becomes
   `… → optimize → strictness → grin → grin-opt → lisp`.
2. **Separate compilation stays.**  Modules are compiled one at a time
   with interface files.  This is the main departure from GRIN as
   published, which is whole-program (§5.3).
3. **Profilable.**  Every generated function and thunk body has a
   readable name, so `sb-sprof` output maps to Haskell source (STRATEGY
   invariant 4).
4. **Incremental and testable.**  Each phase (§10) leaves `make test`
   green and is measured against a benchmark baseline.  The old codegen
   stays selectable (`*backend* = 'flic` vs `'grin`) until the GRIN path
   passes everything.
5. **Both dialects.**  1.2 and 98 share the back end.  The 1.2 demos
   are part of the regression set.
6. **Host-portable in principle.**  Generate portable CL.  SBCL-only
   tricks go behind `#+sbcl` with portable fallbacks (STRATEGY invariant
   3).  Tail calls are the known portability hole (§7.6).

---

## 3. The eval/apply convention, concretely

Marlow & Peyton Jones (2004) compare two conventions:

- **push/enter:** the callee inspects the stack to see how many
  arguments it got;
- **eval/apply:** the caller evaluates the function value, then applies
  it, and the *caller* (or a generic apply routine) checks arity.

On a host language with its own call stack, such as CL, only eval/apply
is practical: we cannot inspect or manipulate the Lisp stack.  Yale is
already eval/apply in spirit, since it forces the function and then
funcalls it.  What it lacks is a cheap arity check and fixed-arity entry
points.

### 3.1 Function values

Replace `make-curried-fn` closures with an explicit object carrying arity:

> **As built (P2, 2026-10-08):** one struct, `fun` (arity, entry), in
> `src/runtime/runtime-utils.mumble`; there is no separate `pap`.  A
> partial application is a `fun` of the remaining arity whose entry
> closes over the supplied arguments (`make-pap`; fixed-arity closures
> for the common shapes, `&rest` beyond them), so `apply-k` tests one
> type.  `apply-1`…`apply-4` are macros: the exact-arity test and
> `funcall` of the entry are inline, and the slow path (PAP,
> over-saturation) is out of line; `apply-n` takes a list.  The
> standard entry is generated per function by `codegen-curried-fn`
> (`backend/codegen.mumble`) as a lambda that forces the strict
> arguments and calls the `/OPT` worker; it is not a separate `/STD`
> defun.  Constructors used as values, and nullary tagged constructors,
> are built once with `load-time-value`.  A plain Lisp function is also
> accepted by `apply-k` and called with the arguments as given: the
> tuple dictionary builders (`tuple-prims.mumble`) are variadic Lisp
> functions that the compiler applies to the component dictionaries.
> The sketch below is kept for reference.

```lisp
;;; src/runtime/eval-apply.lisp (new; plain CL, not mumble — see §8)
(defstruct (fun (:constructor make-fun (arity entry)))
  (arity 0 :type (integer 1 #.call-arguments-limit) :read-only t)
  ;; Fixed-arity CL function taking ARITY boxed (lazy) arguments:
  ;; the "standard entry".
  (entry #'identity :type function :read-only t))

(defstruct (pap (:constructor make-pap (fun args)))
  (fun nil :type fun :read-only t)
  (args '() :type list :read-only t))   ; boxed args supplied so far
```

- A top-level function `f` of arity n gets **two entries**, as today:
  - `|M:f/OPT|`: the worker, taking arguments raw or boxed according to
    `var-strictness`;
  - `|M:f/STD|`: the standard entry, taking n boxed arguments.  It
    forces the strict ones and calls `/OPT`.
- The function *value* `|M:f|` is `(make-fun n #'|M:f/STD|)`, allocated
  once at load time as a constant.
- `/STD` replaces the `&rest`/strictness-list interpretation.  It is
  ordinary generated code with a fixed lambda list, so SBCL compiles it
  to a fast full call.

Anonymous lambdas and local functions that escape become
`(make-fun n (lambda (a1 … an) …))`.  The closure is created only when
the function escapes; a local function called only directly stays a
`labels` function, as today.

**SBCL option.**  `fun` can be a subclass of
`sb-mop:funcallable-standard-object`, so that the object itself is
callable and carries an arity slot.  Measure before adopting it:
funcallable instances are slower to allocate and call through on some
versions.  Start with the plain struct.

### 3.2 Generic apply

A runtime family `apply-1 … apply-4` plus `apply-n` handles unknown
calls.  It plays the role of GHC's `stg_ap_p`, `stg_ap_pp`, … family:

```lisp
(declaim (inline apply-2))
(defun apply-2 (f a b)
  ;; F is already evaluated (WHNF): a FUN or a PAP.
  (typecase f
    (fun (let ((n (fun-arity f)))
           (cond ((= n 2) (funcall (fun-entry f) a b))       ; exact: no consing
                 ((= n 1) (apply-1 (eval (funcall (fun-entry f) a)) b))  ; over-saturated
                 (t (make-pap f (list a b))))))               ; under-saturated
    (pap (apply-pap f a b))
    (t (bad-apply f))))
```

- **Exact application** (the common case) is one type test, one fixnum
  compare and a direct `funcall` of a fixed-arity function.  There is
  no consing.
- **Over-saturation:** call with the first `arity` arguments, `eval` the
  result, then apply it to the rest.
- **Under-saturation:** build a PAP.
- **PAPs:** `apply-pap` appends arguments.  When it reaches the arity it
  calls the entry via `apply`; PAPs are rarer, so the cost is
  acceptable.
- Arities above 4 go through `apply-n` with a list.  Measure the arity
  distribution in the prelude before choosing the cut-off.

Codegen for an unknown call `f a b` (FLIC `flic-app`, not saturated)
changes from `(funcall (force f) (delay a) (delay b))` to
`(apply-2 (eval f) <a> <b>)`, with the arguments boxed as today.

### 3.3 Known calls (unchanged in spirit)

- A saturated call to a known top-level or local function stays a
  direct call of `/OPT` with raw or boxed arguments per strictness.
  This already exists; keep it.
- An over-saturated known call becomes
  `(apply-k (|M:f/OPT| a1…an) rest…)`.
- An under-saturated known call becomes
  `(make-pap |M:f| (list a…))`.  Alternatively the optimizer's
  `do-app-make-saturated` eta-expansion can turn it into a lambda; pick
  whichever allocates less.

### 3.4 Eval

`eval` is "evaluate to WHNF".  It is only cheap if a thunk can be
recognised at runtime, which today's cons representation cannot do.
Hence §4.

```lisp
(declaim (inline eval))
(defun eval (x) (if (thunk-p x) (force-thunk x) x))
```

Static knowledge still matters:

- where box analysis knows a value is evaluated, no `eval` is emitted
  (as today);
- where it knows the value is a thunk, `force-thunk` is called
  directly.

The dynamic test is for the unknown cases only (fields of data, results
of unknown calls, dictionary methods).

---

## 4. Thunks and update

### 4.1 Representation

> **As built (P1, 2026-10-08):** a thunk is a *cons* whose car is one of
> three private marker symbols (unevaluated / blackhole / evaluated),
> not a struct.  It is still distinguishable from every data value (no
> Haskell value is a marker), keeps a thunk at two words (the struct
> below is four on SBCL/arm64 and measured slower), and a blackholed
> thunk keeps its closure, so restoring it is one write.  See
> `src/runtime/runtime-utils.mumble` and bench/RESULTS.md.  The struct
> sketch is kept for reference.

```lisp
(defstruct (thunk (:constructor make-thunk (code)))
  ;; CODE: a nullary closure while unevaluated, +BLACKHOLE+ while being
  ;; evaluated, NIL once evaluated.
  (code nil)
  (value nil))
```

- A distinct struct type gives `thunk-p` (one layout check in SBCL), so
  thunks are distinguishable from every data representation: cons,
  vector, fixnum, `nil`, `t`, `fun`, `pap`.
- This is what allows a generic `eval`, a debug printer that never
  confuses a pair with a thunk, and correct handling of values that
  cross into Lisp.

### 4.2 Force with blackholing

```lisp
(defun force-thunk (th)
  (let ((code (thunk-code th)))
    (cond ((null code) (thunk-value th))                 ; evaluated
          ((eq code +blackhole+) (haskell-loop-error th)) ; <<loop>>
          (t (setf (thunk-code th) +blackhole+)
             (let ((v (funcall code)))
               (setf (thunk-value th) v
                     (thunk-code th) nil)                ; drop closure: no leak
               v)))))
```

- **Space:** clearing `code` fixes today's leak, where the evaluated
  thunk keeps its closure and everything that closure references.
- **Indirections:** a thunk's value may itself be a thunk only if
  codegen forgets to evaluate.  Make it an invariant that `value` is
  always in WHNF; check it under a debug feature.
- **Non-local exits.**  If evaluation is abandoned while a thunk is
  blackholed, the thunk stays blackholed.  This happens through
  `error` → abort, or through an IO exception raised while forcing lazy
  input (`hGetContents`).  A later legitimate force would then report a
  false `<<loop>>`.
  - In batch mode `error` ends the program, so it does not matter there.
  - In the interactive system, and for `catch`, it does.
  - Recommended fix: keep a dynamic stack of blackholed thunks only when
    inside a `catch` or an interactive evaluation (a special variable
    flag).  The handler restores their saved code.  Outside such
    extents, no bookkeeping.
  - The alternative, `unwind-protect` in every force, is correct but
    costs on every thunk.

### 4.3 Thunks that need no update

- GRIN's "update elimination" (§5.4) removes updates for thunks used at
  most once.  In the meantime, `make-haskell-string`'s magic delays
  (`runtime-utils.mumble:283-304`) become a `thunk` subtype or a plain
  closure-based thunk.
- Constant boxes (`'(#t . 3)` today) become the value itself.  Since a
  WHNF value is not a thunk, it needs no box at all, and `box` becomes
  the identity.  This removes an allocation per boxed constant and per
  `box` site.

### 4.4 Code to change for the new thunk representation

Every place that builds or inspects the cons representation:

- `delay`, `box`, `unbox`, `forced?`, `force`, `force-inline`
  (`runtime-utils.mumble`);
- `delay?` (`debug-utils.mumble`);
- `prim.strict1`, `prim.force`, `prim.getres`, `prim.returnio`, the
  array prims (`array-prims.mumble`);
- the IO prims returning `(box (io-success))`;
- `apply-exec` (`(funcall fn (box 'state))`);
- `prim.dict-sel` and tuple dictionaries (`tuple-prims.mumble`);
- `prim.append`'s peeling of `(box '())`;
- `codegen-exported-types` accessors that `force`;
- every `.hi` `LispName` primitive marked `NoConversion` that receives
  boxed arguments.

`grep -n "box\|delay\|force" src/runtime/*.mumble` is the checklist.

---

## 5. The GRIN-style IR

### 5.1 Why GRIN, and what we take from it

GRIN (Boquist 1999; Podlovics, Hruska & Pénzes 2020) is a first-order,
untyped-at-the-heap, monadic IR.  Laziness is *explicit*:

| Laziness operation | Expressed as |
|---|---|
| suspension | `store` of an `F`-node (a suspended call) |
| forcing | a call to `eval` |
| update | `update` |
| partial application | a `P`-node, applied by `apply` |

All of these are ordinary operations the optimizer can see and remove.
That is what makes it a good bridge to an eager target like CL.  Compared
to STG:

- STG keeps closures as the primitive and laziness implicit in `let`
  and `case`.
- GRIN exposes the heap operations, so transformations such as unboxing
  return values, update elimination and eval inlining are local rewrites
  on the IR, not changes to the runtime.

### 5.2 The IR ("LGRIN": Lisp-targeted GRIN)

```
prog  ::= def*
def   ::= f x1 … xn = exp                     -- first-order; xi are simple vars
exp   ::= sexp ; \lpat -> exp                 -- bind (monadic sequencing)
        | case val of alt+                    -- on a node tag or a literal
        | sexp
sexp  ::= f v1 … vn                           -- saturated call of a known function
        | apply v w1 … wk                     -- unknown call (eval/apply, §3.2)
        | eval v                              -- to WHNF (§3.4)
        | unit val                            -- return a value
        | store val                           -- allocate a node, return pointer
        | fetch v [i]                         -- read node / field i
        | update v val                        -- overwrite a thunk with its value
        | prim p v1 … vn                      -- a LispName primitive
        | (exp)
val   ::= (tag v1 … vn) | tag | lit | v | ()  -- complete node, bare tag, literal
tag   ::= Ccon                                -- constructor
        | Ff                                  -- suspended saturated call of f
        | Pn f                                -- partial application missing n args
lpat  ::= val                                 -- bind a node pattern or a var
alt   ::= cpat -> exp
```

The definition is first-order: there are no lambdas.  Lambda-lifting
happens during lowering (§5.5).  Variables carry a **representation
type**, which is the only typing GRIN needs here:

| Rep | Meaning |
|---|---|
| `ptr` | a heap value: a possibly unevaluated Haskell value (a boxed value in today's terms) |
| `whnf` | an evaluated heap value |
| `fixnum`, `double`, `single`, `char` | unboxed primitives |
| `bool` | Lisp `t`/`nil` |

Representation types come from:

- box analysis (`ptr` vs `whnf`);
- primitive signatures (`LispName` prims and their `.hi` types);
- the type checker's `var-type`.  This is a new dependency: the back end
  currently ignores types.  It is needed to know that a `whnf` value is
  an `Int` and can be a `fixnum` (§9).

Define it as mumble structs in `src/compiler/grin/grin-structs.mumble`,
following the `define-flic` pattern (BOA constructors, a walker macro and
a printer), so the existing tooling idioms carry over.

### 5.3 Separate compilation: an open `eval`

Published GRIN is whole-program.  `eval` is *generated*: a `case` over
every `F`-tag in the program, which a heap-points-to analysis then
specialises.  Yale compiles modules separately, so:

- **Global `eval` is a runtime function** (§3.4).  An `F`-node is
  represented as a `thunk` whose closure performs the call.  The tag set
  stays open, as GHC does it.
- **Local specialisation replaces global points-to.**  Within a module
  the lowering knows, at many `eval` sites, which `F`-tags can reach a
  variable.  Examples: a `let`-bound thunk used in the same function, or
  a field of a node built in the same function.  There `eval` is
  inlined to a direct call, with no thunk allocated at all.
  - This is the in-module analogue of GRIN's "eval inlining" plus
    "sparse case".
  - An intraprocedural analysis is enough to start with.
  - Interface files can export per-function "returns a node with these
    tags" summaries later.
- **Optional whole-program mode (later, §10 P6).**  For a release build
  of a fixed program, the dumped FLIC of all modules could be linked and
  run through full GRIN, with a generated eval and points-to analysis.
  Not before everything else works.

### 5.4 Optimisations worth having (in order of value for cost)

1. **Eval inlining and known-tag case** (local, §5.3): `case` on a
   variable whose tag is known folds; `eval` of a known `F`-node becomes
   a direct call.
2. **Update elimination**: a thunk demanded at most once needs no
   `update`, and its closure need not be shareable.
   - Start with the syntactic single-use case: a `let` thunk referenced
     once in a strict position becomes a direct call (box analysis
     already catches much of this).
3. **Unboxed returns / vectorisation**: a function whose result is
   always a known constructor returns its fields with CL `values`
   instead of allocating (§7.4).
   - Example: IO's `IOResult a` (untagged already) and pair-returning
     helpers such as `quotRem`.
4. **Worker/wrapper with unboxed arguments**: `/OPT` takes `fixnum` or
   `double-float` for strict `Int`/`Double` args (needs representation
   types, §9).  `/STD` boxes and unboxes.
5. **Arity raising**: a function returning a lambda gets its arity
   raised, so calls become saturated (`f x = \y -> …`).
6. **Dead parameter and dead field elimination** (within a module).
7. **Case-of-case and copy propagation** on GRIN, cleaning up after 1–6.

Leave the heap-points-to analysis, interprocedural sparse-case and
generated eval to the whole-program mode.

### 5.5 Lowering FLIC → GRIN

Lowering runs after `strictness` (which includes box analysis), using its
annotations:

| FLIC (with box annotation) | GRIN |
|---|---|
| `lambda` at top level | a `def` |
| local `lambda` that escapes | lambda-lifted to a top-level `def` over its free vars, value `(Pn f fv…)` (a `fun` closure at the Lisp level) |
| local `lambda` called only directly | a local `def` (becomes `labels`) |
| `let x = e` with `x` strict | `e' ; \x ->` |
| `let x = e`, lazy, `e` cheap and WHNF | `store (C …)` or `unit v` |
| `let x = e`, lazy, not cheap | `store (Ff fv…)`: a thunk; `f` is a lifted def of `e` |
| `letrec` of values | stores, then `update`s (or the CL `let` + `setf` pattern used today) |
| saturated `app` of known `f` | `f args` (args already raw or boxed per strictness) |
| unknown `app` | `eval g ; \g' -> apply g' args` |
| `pack` applied (saturated) | `store (Ccon args)`, or `unit (Ccon args)` when the result is consumed immediately |
| `case-block` + `is-constructor` tests on one variable | `case` on its tag (recover a `case` from the test chain; §7.3) |
| `sel con i x` | `fetch x [i]` |
| `force` (box table) | `eval` |
| `delay` (box table) | `store (F…)` |
| `box` | `unit` (no-op under §4.3) |
| `unbox` | none (the value is already WHNF) |

Recovering a real `case` from FLIC's `case-block`/`and` chains is worth
doing in the lowering.  Today's match compiler emits chains of
`is-constructor` tests on the same scrutinee, and a `case` gives CL jump
tables (§7.3).

### 5.6 Example: `map`

The Haskell source:

```haskell
map f []     = []
map f (x:xs) = f x : map f xs
```

GRIN, with `f` lazy and `l` strict (WHNF) per strictness:

```
map/opt f l =
  case l of
    CNil     -> unit CNil
    (CCons x xs) ->
      store (Fap1 f x) ; \hd ->      -- thunk: f x
      store (Fmap f xs) ; \tl ->     -- thunk: map f xs (note: xs is ptr)
      unit (CCons hd tl)

ap1 f x = eval f ; \f' -> apply f' x
map f xs = eval xs ; \l -> map/opt f l   -- the F-node entry: xs may be a thunk
```

CL produced (§7):

```lisp
(defun |PreludeList:map/OPT| (f l)
  (if (consp l)
      (cons (make-thunk (named-thunk |PreludeList:map/ap1| (apply-1 (eval f) (car l))))
            (make-thunk (named-thunk |PreludeList:map/rec|
                          (|PreludeList:map/OPT| f (eval (cdr l))))))
      '()))
```

`named-thunk` expands to a named closure (§8), so a profiler attributes
time to `map/ap1` rather than to an anonymous lambda.

---

## 6. Mapping GRIN onto Common Lisp

### 6.1 The heap is the Lisp heap

The suggestion in GEMINI-NOTES to map GRIN's heap onto "an unboxed Lisp
array or arena" is **rejected** for this project:

- the CL garbage collector is generational, precise and tuned for
  exactly this kind of allocation;
- an array heap would need our own GC and would lose the Lisp debugger,
  inspector and profiler;
- it would also break Lisp interop.

| GRIN | CL |
|---|---|
| pointer | object reference |
| `store` | allocation |
| `fetch` | slot or field access |
| `update` | setting the thunk slots |

### 6.2 Node representation

Keep today's specialised representations; they are good:

| Haskell value | Representation |
|---|---|
| `[]` / `:` | `nil` / cons |
| Bool | `nil` / `t` |
| enumeration | fixnum tag |
| single-constructor type of arity 1 | the field itself |
| single-constructor type of arity 2 | cons |
| single-constructor type of arity ≥ 3 | `simple-vector` |
| other sum types | `(simple-vector tag f1 … fn)` |

Changes:

- **Nullary constructors of non-enum types** are preallocated once per
  constructor (a load-time constant `#(tag)`), not allocated per use.
- **`thunk`, `fun` and `pap`** are structs (§3, §4), distinct from all of
  the above.
- **Optionally, later:** one `defstruct` per constructor for large sum
  types, so `typecase` dispatches on the layout.  Measure against
  vector+tag first; SBCL `case` on a fixnum tag is a jump table.

### 6.3 Functions

| GRIN | CL |
|---|---|
| GRIN `def` | `defun` with `(declaim (ftype (function (…) …) name))` derived from representation types |
| local defs | `labels` / `flet` |
| unknown calls | `apply-k` (§3.2) |

Keep `|Module:name/OPT|` and `/STD` names.

### 6.3a The eval/apply entry points per function

| Entry | Arguments | Used by |
|---|---|---|
| `|M:f/OPT|` | per strictness: raw (possibly unboxed fixnum/double) or `ptr` | known saturated calls |
| `|M:f/STD|` | n `ptr`s | `apply-k` via the `fun` object |
| `|M:f|` | — (a `fun` value) | first-class uses |

### 6.4 Multiple return values

Unboxed returns map to `values` / `multiple-value-bind`:

- SBCL returns a small fixed number of values in registers, so this is
  allocation-free.
- It is the CL counterpart of GRIN's vectorised returns and GHC's
  unboxed tuples.

### 6.5 Case

- `case` on fixnum tags → CL `case`.  SBCL ≥ 2.0.2 compiles dense
  integer `case` to a jump table.
- Two-way splits (list, Bool, `Maybe`) stay `if`.
- Literal cases on `Char`/`Int` → `case`; on strings → the existing
  `primStringEq` chain.

### 6.6 Tail calls

- CL does not guarantee tail calls.  SBCL performs tail-call merging for
  full and local calls in compiled code unless the `debug` quality is
  high.  Our generated code uses `debug 0`, so SBCL merges.  Lock this
  in with a test: a 10⁷-iteration tail-recursive loop, and an IO
  `mapM_` over a long list, must not overflow the 512 MB stack.
- Tail position must be preserved by construction:
  - `eval` and `apply-k` in tail position are calls, so they are fine;
  - an `update` after a call breaks it, which is inherent in lazy
    update;
  - a `store`, `fetch` or `unit` wrapper around a tail call must not be
    introduced.
- **Portability:** ECL merges self-tail calls only in some cases; ABCL
  (JVM) does not merge tail calls.  A trampolined mode (each `/OPT`
  returns a continuation) would fix it at a large cost.  Do not build it
  unless a second host becomes a goal; document the restriction instead.

### 6.7 Declarations

- Generated code keeps `(speed 3) (safety 0)` (today's `*code-quality*`
  2).
- With representation types, emit `(declare (type fixnum …))` and
  `(type double-float …)` for unboxed variables.  This is what turns
  `Int` arithmetic into machine arithmetic.
- `Int` overflow stays undefined at safety 0 (STRATEGY BUG-2 documents
  it).
- For a debug build, `*code-quality* 1` gives safety 1 with type checks,
  and that should keep the generated code correct.  Run the test suite
  in that mode in CI to catch representation errors that safety 0 hides.

---

## 7. Interaction with the rest of the system

### 7.1 Interface files

`-hci` dumps must add:

- the representation of each function's arguments and result, beyond
  `strictness`;
- the `/STD` and `/OPT` entry names.

Bump a format version in `dump-params.mumble`, so that stale interface
binaries are recompiled rather than misread (STRATEGY invariant 7).  The
prelude unit is `:stable`; delete its binaries after the change
(`make clean`).

### 7.2 Primitives (`LispName`)

- Prims keep their calling convention: raw arguments where `Strictness`
  says `S`, `ptr` where `N`.
- With representation types, a prim's `.hi` type determines whether an
  `S` argument is a `fixnum` or a generic object.  No `.hi` file needs
  to change except prims that build or inspect thunks (§4.4).

### 7.3 Pattern-match compilation

The current match compiler (cfn) is unchanged.  The `case` recovery in
§5.5 works on its output.  A better match compiler (decision trees,
Wadler/Augustsson) is out of scope here, but GRIN `case` is the natural
target if one is written later.

### 7.4 IO

`IO a = SystemState -> IOResult a` with the newtype erased, `SystemState`
= fixnum 0, and `IOResult` untagged.  An IO action is a one-argument
function.  With §5.4 item 3, `thenIO`'s `getState`/`getRes` plumbing
disappears into `values`.

- **Invariant (STRATEGY LG-IO):** `thenIO` must remain a tail call to
  the continuation.
- Add an IO-loop stack test (§6.6).

### 7.5 Lisp interop

`ImportLispType` and `ExportLispType` types and the X11 interface (1.2)
see Haskell values.  With distinct thunk objects, an exported accessor
must `eval` lazy fields; that is a one-line change in
`codegen-exported-types`.

### 7.6 Exceptions

- `error` → `haskell-runtime-error` stays a non-local exit.
- IO `catch` stays `handler-case`, plus the blackhole restore of §4.2.

---

## 8. Implementation language and profiling hooks

- **The new runtime core** (`thunk`, `fun`, `pap`, `eval`, `apply-k`,
  `force-thunk`) should be **plain CL** in `src/runtime/eval-apply.lisp`.
  This follows the mumble decision: host-facing code may be CL.  It is
  small, performance-critical, and benefits from CL declarations and
  `inline` written directly.  Load it as a CL file before the mumble
  runtime units: a `:file` component in `yale-haskell.asd`, and a
  `load-compiled-cl-file` in `cl-init.lisp`.
- **The GRIN passes** (`src/compiler/grin/`) are mumble, like the rest
  of the compiler.
- **Thunk bodies are named** closures: `(named-thunk name form)` expands
  to `(make-thunk (flet ((name () form)) #'name))`.  On SBCL this could
  use `sb-int:named-lambda`, but `flet` is portable and SBCL shows its
  name in backtraces and in `sb-sprof`.
- **Add a profiling mode** (`*code-quality*` 1 plus `(debug 1)`) and a
  `make profile FILE=…` target running `sb-sprof` with the report
  sorted by `|Module:name|`.  This keeps the "not hard to profile" goal
  (notes) honest.

---

## 9. Representation types: the one new front-end dependency

Unboxing `Int` and `Double` (§5.4 item 4, §6.7) needs to know a variable's
Haskell type at the back end.  The FLIC nodes carry no types, but vars
carry `var-type` from the type checker.

- **Minimum:** for lambda parameters and let-bound vars whose `var-type`
  is (after expanding synonyms and newtypes) `Int`, `Char`, `Float`,
  `Double` or `Integer`, and which box analysis marks strict, assign a
  representation type.
- Polymorphic and overloaded vars stay `ptr` or `whnf`.
- Specialisation of overloaded functions (`SPECIALIZE`, or automatic for
  `Num Int`) is a separate, later optimisation.  It is what makes
  `sum :: [Int] -> Int` fast when written as `Num a => [a] -> a`.
- Be careful with dictionary parameters and with types the optimizer
  has changed by inlining.  Types are only reliable on vars the type
  checker produced.  Vars introduced by the optimizer (`copy-flic`
  renames) must copy `var-type`.

---

## 10. Phased plan

Each phase is one or more commits with `make test` green, the 1.2 demos
passing, and benchmark numbers recorded.

| Phase | Work | Done when |
|---|---|---|
| **P0 Benchmarks** ✅ | `bench/` with nofib-style programs: nfib, queens, primes/sieve, wheel-sieve, an Integer-heavy one, an IO loop, `Data.Map`-style tree code.  A `make bench` target timing each with the H98 image | Baseline numbers committed in `bench/RESULTS.md` |
| **P1 Thunks** ✅ | `thunk` struct, blackholing with catch-scoped restore, closure clearing, constant boxes become plain values (§4) on the *current* codegen | Tests green; a `<<loop>>` test; memory of a long lazy-list program reduced |
| **P2 Eval/apply** ✅ | `fun`, `pap`, `apply-1…4/n`, `/STD` entries, preallocated nullary constructors; codegen emits `apply-k` for unknown calls (§3) | Tests green; no `&rest` in the runtime's call path; higher-order benchmarks faster |
| **P3 Case** | Recover `case` from match chains and emit CL `case` (§5.5, §6.5) — still in the old codegen | Tests green; dispatch-heavy benchmarks faster |
| **P4 GRIN IR** | `src/compiler/grin/` structs, printer, FLIC→GRIN lowering, GRIN→CL emission reproducing P1–P3 output; `*backend*` switch; the `grin` printer in `*printers*` | Both backends pass all tests; output equivalent |
| **P5 GRIN optimisations** | §5.4 items 1–3 (eval inlining, update elimination, unboxed returns), then 4–5 with representation types (§9) | Each with tests and benchmark deltas recorded.  The GRIN path stays in the repository on its merits (it is the base for later optimisations and other back ends), not only if it wins on the benchmarks; the old codegen is removed once GRIN is correct everywhere and not slower by more than noise |
| **P6 Whole-program (optional)** | Link-time GRIN over all modules' FLIC with generated eval and points-to | Only if P5 leaves a large gap |

P0 and P1 can run alongside the H98 front-end work, because they do not
touch the front end.  P2 changes runtime calling conventions that every
`.hi` prim and runtime helper sees; do it in one focused effort.

---

## 11. Invariants (in addition to STRATEGY.md's cross-cutting ones)

1. A WHNF value is never a `thunk`; a `thunk`'s `value` is always WHNF.
2. `/OPT` is called only with exactly `arity` arguments in the
   representations its strictness and rep types declare; `/STD` only
   with `ptr`s.
3. `eval` is idempotent and cheap on WHNF values.
4. Tail calls in Haskell source are tail calls in the generated Lisp,
   except where an update is semantically required.  Tested by a deep
   tail-recursion test and an IO loop test.
5. Every generated function and thunk body has a readable name derived
   from the Haskell binding.
6. The interface format version changes whenever calling conventions or
   representations change.
7. 1.2 and 98 share the back end; neither may regress on the benchmarks
   by more than noise without a recorded reason.

---

## 12. References

- S. Marlow, S. Peyton Jones.  *Making a fast curry: push/enter vs.
  eval/apply for higher-order languages.*  ICFP 2004; JFP 2006.  §3
  follows its eval/apply design: arity in the function object, generic
  apply, PAPs.
- U. Boquist.  *Code Optimisation Techniques for Lazy Functional
  Languages.*  PhD thesis, Chalmers, 1999.  The original GRIN: eval/apply
  as generated functions, heap points-to analysis, update elimination,
  vectorisation.
- P. Podlovics, C. Hruska, A. Pénzes.  *A Modern Look at GRIN, an
  Optimizing Functional Language Back End.*  2020.  The modernised GRIN
  and its transformation catalogue (§5.4).
- S. Peyton Jones.  *Implementing lazy functional languages on stock
  hardware: the Spineless Tagless G-machine.*  JFP 1992.  For comparison
  (§5.1), and for blackholing and update.
- M. Piróg, J. Gibbons et al.  *From Push/Enter to Eval/Apply by Program
  Transformation.*  2016.
- The current back end: `src/compiler/backend/README`,
  `src/compiler/flic/README`, and the headers of `codegen.mumble` and
  `box.mumble`.
