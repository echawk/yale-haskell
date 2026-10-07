# STRATEGY-CODE.md — Reference implementations for `doc/STRATEGY.md`

This document gives clean reference implementation code for each section of
[`STRATEGY.md`](STRATEGY.md), **in order**, assuming all prior dependencies
were met. It is a planning artifact: it conveys *how the code should be
written*, in the repo's actual dialect (**mumble**, `.mumble`), using the
repo's real conventions, so that another model can implement it against the
cited source files.

> **Do not modify source code based on this document alone.** Like
> STRATEGY.md, this is a planning artifact. Read the cited source files
> first, then implement.

### Conventions used throughout (verified against the source)

These are not suggestions — they are the patterns the existing code follows,
and every snippet below obeys them:

- **Language: mumble** (`.mumble`), read in `MUMBLE-USER`. Top-level forms are
  `define` (≈ Scheme `define`), `define-struct`, `define-syntax`,
  `define-local-syntax`. Booleans are `#t`/`#f` (the source often writes them
  quoted as `'#t`/`'#f` in initializers and `setf`; both read identically —
  this document follows the source and quotes them in assignments).
- **Dialect gating**: *all* dialect-dependent code uses
  `(feature? 'name)` from `src/compiler/top/globals.mumble`. **Never** raw
  `(haskell98?)` for new code (STRATEGY invariant 2). New features are added
  to `*dialect-features*` there.
- **Errors** go through `src/compiler/top/errors.mumble`:
  `(fatal-error 'id "msg" args)`, `(recoverable-error 'id "msg" args)`,
  `(phase-error 'id "msg" args)`, `(haskell-warning 'id "msg" args)`,
  `(compiler-error 'id "msg" args)`. Every error has a stable symbol `id`.
  Output goes to `*error-output-port*`.
- **Functions** are referenced with `(function f)` and called with `funcall`
  (mumble is Lisp-1 but, like CL, needs `function` to get a function value).
- **Special/dynamic variables** are read with `(dynamic *var*)` and bound with
  `dynamic-let`. Examples in active use: `*non-generic-tyvars*`,
  `*placeholders*`, `*context*`, `*phase*`, `*modules*`, `*module*`,
  `*default-decls*`.
- **Core classes/types** are reached via `(core-symbol "Name")` (a macro → a
  global variable holding the `def`). Core-symbol wiring lives in
  `src/compiler/top/core-symbols.mumble`.
- **AST builders** are the `**`-prefixed quoting macros
  (`**define`, `**case/con`, `**var`, `**var/def`, `**con/def`, `**app`,
  `**app/l`, `**let`, `**lambda/pat`, `**var-pat/def`, `**showsPrec`,
  `**readsPrec`, `**showParen`, `**readParen`, `**showString`, `**string`,
  `**int`, `**dot`, `**dot/l`, `**tuple2`, `**listcomp`, `**gen`, `**lex`,
  `**tycon/def`, `**context`, `**class/def`, `**signature`, …). Derived
  instances are *generated* code built with these, not hand-written Haskell.
- **Structs**: `define-struct`, `make`, `with-slots`, `update-slots`,
  `struct-slot`. Struct accessors are `<type>-<slot>`.
- **Phase plumbing**: a new pass is a new `.mumble` unit wired into
  `src/compiler/tdecl/` (or the relevant dir) and declared in
  `src/compiler/system.mumble`'s unit graph, *between* its neighbours in the
  sacred pipeline order
  `parse → import/export → tdecl → derived → prec/scope → depend → type → cfn → flic → optimize → strictness → codegen → Lisp`.

> **Ambiguity notes** are called out in blockquotes with a **Recommendation**
> aligned to the repo's goals (keep the architecture; gate on features; 1.2
> must not break; interface files must round-trip; don't copy nhc98).

---

## Table of contents (maps 1:1 to STRATEGY.md sections)

1. How to use / Pipeline reference
2. Dialect gating
3. Status summary
4. LG-CCONSTRUCTOR — kind inference (the remaining gap)
5. LG-DO
6. LG-IO
7. LG-NEWTYPE
8. LG-SHOW-READ  *(M5 — active)*
9. LG-RECORDS  *(M6)*
10. LG-QUALIFIED  *(M7)*
11. LG-IMPTEXP
12. LG-DERIVING
13. LG-POLYREC  *(M9)*
14. LG-MR2
15. LG-DEFAULT
16. LG-LOCALFIXITY … LG-RESERVED (the landed M2 wins)
17. LG-UNICODE  *(M9)*
18. Prelude and library gaps
19. RT-DICTLAYOUT
20. Open bugs BUG-1 … BUG-9
21. Cross-cutting invariants
22. Milestone ordering

---

## 1. How to use / Pipeline reference

No implementation code — these are reference/navigation sections of
STRATEGY.md. The pipeline order and phase directories are authoritative; a
new pass must slot into `system.mumble`'s unit graph at its phase boundary.
See the "Conventions" preamble above for the patterns every later snippet
uses.

---

## 2. Dialect gating

The single mechanism every dialect-dependent snippet depends on. This is the
real, current code in `src/compiler/top/globals.mumble` (verbatim shape). New
work *adds a feature here* and gates on it; it does not branch on the
dialect.

```mumble
;;; src/compiler/top/globals.mumble  (existing — extended by LG-QUALIFIED etc.)

(define *dialect-order* '(haskell-1.2 haskell-1.3 haskell-1.4 haskell98))

(define *dialect-features*
  '(;; syntax and the type system
    (constructor-classes haskell-1.3 #f)
    (do-notation         haskell-1.3 #f)
    (newtype             haskell-1.3 #f)
    (show-read           haskell-1.3 #f)   ; Show and Read instead of Text
    (show-method         haskell98 #f)     ; `show' is a method of Show
    (monad-fail          haskell98 #f)     ; else MonadZero(zero)
    ;; lexical differences of Haskell 98
    (h98-lexing          haskell98 #f)
    (headerless-main     haskell98 #f)
    (fixity-anywhere     haskell98 #f)
    ;; added by LG-QUALIFIED (M7):
    (qualified-names     haskell98 #f)))

(define (feature? name)
  (let ((entry (assq name *dialect-features*)))
    (when (eq? entry '#f)
      (error "Unknown dialect feature ~A" name))
    (and (dialect>=? (cadr entry))
         (or (eq? (caddr entry) '#f)
             (<= (dialect-index *haskell-dialect*)
                 (dialect-index (caddr entry)))))))
```

A feature entry is `(name first-dialect last-dialect)`; `#f` for
`last-dialect` means "to the end". `feature?` errors on an unknown name, so a
typo fails loudly rather than silently taking the 1.2 path.

> **Note (verified):** the live table currently has **8** entries — there is
> **no** `qualified-names` row, confirming LG-QUALIFIED has not started. The
> `qualified-names` line above is the addition LG-QUALIFIED makes.

---

## 3. Status summary

No implementation code. Reflects post-§9 state: constructor classes, `do`,
`newtype`, monadic IO, and all M2 cheap wins have landed. Active work is M5
(Show/Read).

---

## 4. LG-CCONSTRUCTOR — kind inference (the remaining gap)

**Status:** constructor classes/higher kinds landed. **Remaining gap:** there
is no kind checker; a kind mismatch surfaces as an obscure arity/unification
error ("kind mismatch" in `unify-args`). This adds kind inference.

**Where:** new file `src/compiler/tdecl/kind-inference.mumble`, run after
`tdecl` and before `type`; augment `src/compiler/ast/type-structs.mumble` with
kind slots.

### 4.1 Kind representation

```mumble
;;; src/compiler/ast/type-structs.mumble  (additions)

;;; Kinds:  *  and  k1 -> k2.  Kind variables are union-find cells used only
;;; during inference; they are generalised away before types are serialised.

(define-struct kind-star
  (predicate star?))

(define-struct kind-arrow
  (predicate karrow?)
  (slots
   (from (type kind))
   (to   (type kind))))

(define-struct kvar                       ; an inference kind variable
  (predicate kvar?)
  (slots
   (link (type (maybe kind)))))           ; union-find pointer; '#f = unbound
```

> **Ambiguity — where to store kinds.** STRATEGY offers two options: a `kind`
> slot on `tyvar`/`tycon`, or a separate kind-inference table.
>
> **Recommendation: store on the defs, not on `tyvar`/`tycon` AST nodes.**
> The type checker resolves a `tycon` to its `def` (an `algdata`) via
> `tycon-def`; a class's type variable resolves to the `class` def. Storing
> the *constructor's* kind on the `algdata`/`class` def (one value per type,
> not per AST occurrence) keeps inference cheap and makes interface
> round-tripping trivial (invariant 7): the kind is a property of the type
> definition, dumped/loaded beside the type.
>
> **Critical name clash (verified):** `class.mumble` *already* uses the slot
> name `class-kind` for the **defaulting category** (`'numeric`/`'Standard`/
> `'other`, set by `find-class-kind`). Reusing it would clobber defaulting.
> Use **`class-var-kind`** (kind of the class's type variable) and
> **`algdata-kind`** (kind of the type constructor).

```mumble
;;; Add slots (do NOT rename the existing class-kind defaulting slot):
;;;   algdata  -> (kind (type kind) (default (make kind-star)))
;;;   class    -> (var-kind (type kind) (default (make kind-star)))
```

### 4.2 Kind unification (union-find over `kvar`)

```mumble
;;; src/compiler/tdecl/kind-inference.mumble

(define (kstar) (make kind-star))
(define (karrow f t) (make kind-arrow (from f) (to t)))

(define (kind? k) (or (star? k) (karrow? k) (kvar? k)))

;;; Follow the union-find chain to the representative.
(define (kind-head k)
  (cond ((kvar? k)
         (cond ((kvar-link k)
                => (lambda (r)
                     (let ((r (kind-head r)))
                       (setf (kvar-link k) r)        ; path compression
                       r)))
               (else k)))
        (else k)))

(define (kvar-bind kv k)
  (setf (kvar-link kv) k)
  '#t)

(define (kind-unify k1 k2)
  (let ((k1 (kind-head k1))
        (k2 (kind-head k2)))
    (cond ((and (star? k1) (star? k2)) '#t)
          ((kvar? k1) (kvar-bind k1 k2))
          ((kvar? k2) (kvar-bind k2 k1))
          ((and (karrow? k1) (karrow? k2))
           (and (kind-unify (kind-arrow-from k1) (kind-arrow-from k2))
                (kind-unify (kind-arrow-to k1) (kind-arrow-to k2))))
          (else
           (phase-error 'kind-mismatch
             "Kind mismatch: ~A does not match ~A."
             (kind->string k1) (kind->string k2))))))

(define (kind->string k)
  (let ((k (kind-head k)))
    (cond ((star? k) "*")
          ((karrow? k)
           (string-append (kind->string (kind-arrow-from k)) " -> "
                          (kind->string (kind-arrow-to k))))
          (else "?"))))
```

### 4.3 Kind of a type, given an environment

`apply-kind fk (a1..an)`: `fk` must be `k1->...->kn->r`; unify each `ki`
with the corresponding argument kind; return `r`.

```mumble
;;; Compute the kind of a type, unifying against the constructor's stored
;;; kind.  kenv maps tyvar names -> kind (a kvar if not yet constrained).
(define (kind-of-type type kenv)
  (cond ((tyvar? type)
         (let ((k (table-entry kenv (tyvar-name type))))
           (if (eq? k '#f)
               (let ((kv (make kvar)))
                 (setf (table-entry kenv (tyvar-name type)) kv)
                 kv)
               k)))
        ((tyapp? type)
         (let ((fk (kind-of-type (tyapp-fun type) kenv))
               (aks (map (lambda (a) (kind-of-type a kenv))
                         (tyapp-args type))))
           (apply-kind fk aks type)))
        (else                       ; tycon
         (let ((ck (algdata-kind (tycon-def type)))   ; stored constructor kind
               (aks (map (lambda (a) (kind-of-type a kenv))
                         (tycon-args type))))
           (apply-kind ck aks type)))))

(define (apply-kind fk args ctxt)
  (do ((fk fk (kind-arrow-to fk))
       (args args (cdr args)))
      ((null? args) fk)
    (when (not (karrow? fk))
      (phase-error 'over-application
        "Type is applied to too many arguments: ~A" ctxt))
    (kind-unify (kind-arrow-from fk) (car args))))
```

### 4.4 Inferring constructor kinds

A `data T a1 … an = …` declaration gives `T :: * -> … -> *` (n arrows) purely
from the arity of the LHS — no inference needed.

```mumble
(define (arity->kind n)
  (do ((i 0 (1+ i))
       (k (kstar) (karrow (kstar) k)))
      ((= i n) k)))

(define (infer-data-kind alg)
  (arity->kind (length (algdata-tyvars alg))))
```

### 4.5 Inferring a class variable's kind

`class C f where meth :: f a -> f b -> …` constrains `f`'s kind from how it
is *applied* in method signatures. Start `f`'s kind as a fresh `kvar` and
unify against every `tyapp` whose function is `f`.

```mumble
;;; class-var is the symbol naming the class's type variable.
(define (infer-class-var-kind class-decl)
  (let ((class (class-ref-class (class-decl-class class-decl)))
        (vname (class-decl-class-var class-decl))
        (kenv (make-table))
        (vk (make kvar)))
    (setf (table-entry kenv vname) vk)
    (dolist (decl (class-decl-decls class-decl))
      (when (is-type? 'signdecl decl)
        (kind-of-type (signature-type (signdecl-signature decl)) kenv)))
    (let ((final (kind-head vk)))
      ;; A class variable must have kind * -> ... -> * (at least one arrow),
      ;; never a bare *.  Rejecting * here is the "kind inference" payoff:
      ;; `class C f where meth :: f` fails clearly instead of as a unifier
      ;; arity error later.
      (when (star? final)
        (phase-error 'bad-class-kind
          "Class ~A's type variable is used at kind *, but a constructor~%~
           class needs kind * -> ... -> *."
          (def-name class)))
      (generalise-kind final))))
```

### 4.6 The pass

```mumble
;;; Called from system.mumble AFTER tdecl has built algdata/class defs and
;;; BEFORE type.  Stores the inferred kind on each def.
(define (infer-kinds modules)
  (walk-modules modules
    (lambda ()
      (dolist (alg (module-alg-defs *module*))
        (setf (algdata-kind alg) (infer-data-kind alg)))
      (dolist (c (module-classes *module*))
        (setf (class-var-kind c)
              (infer-class-var-kind c)))
      ;; Synonyms: kind = arity of the LHS, like data.
      (dolist (syn (module-synonyms *module*))
        (setf (algdata-kind syn) (arity->kind (length (synonym-args syn))))))))
```

**Wiring:** add a unit `(unit kind-inference (source-filename "kind-inference.mumble"))`
to `src/compiler/tdecl/tdecl.mumble`'s `define-compilation-unit`, `require` it
after `class`/`instance`, and call `infer-kinds` from the driver between the
`tdecl` and `derived` phases.

### 4.7 Tests & invariants (per STRATEGY)

`tests/haskell98/language/higher-kinds.hs` defines `GRose f a = GNode a (GRose f (f a))`,
constructs a value, prints it; add a `.xfail` for nested higher-kinded
recursion. Invariants: existing `Maybe`/`Either`/`[]`/`(->)` instances still
type-check; partially applied instance heads still resolve; **interface files
serialise kinds** (`backend/interface-codegen.mumble` +
`backend/dump-interface.mumble` must emit/read `algdata-kind`/`class-var-kind`
— see §7 invariant).

> **Ambiguity — kind variables in interface files.** `kvar` cells are
> inference-only and must never reach a `.hu` file.
> **Recommendation:** `generalise-kind` (called in 4.5) replaces every
> remaining `kvar` with `*` (the only ground kind a free kind variable can
> take) before storage, so dumped kinds are always ground `*`/`karrow`.

---

## 5. LG-DO — `do` notation

**Status:** landed. Desugaring is in `src/compiler/prec/scope.mumble`
(`desugar-do`, `desugar-do-bind`, `do-failure-exp`). Shown for completeness;
the only code worth adding is the **failure-method gate**, which is the
maintainable seam.

```mumble
;;; src/compiler/prec/scope.mumble  (canonical shape)

;;; do { p <- e1; e2 }  ==>  e1 >>= \p -> e2          (p failure-free)
;;;                     ==>  e1 >>= \v -> case v of { p -> e2; _ -> fail s }  (otherwise)
;;; do { e1; e2 }       ==>  e1 >> e2
;;; do { let p = e; r } ==>  let p = e in do { r }

(define (desugar-do stmts)
  (cond ((null? stmts)
         (**var/def (core-symbol "return")))            ; do {} = return
        ((is-type? 'do-generator (car stmts))
         (desugar-do-bind (car stmts) (desugar-do (cdr stmts))))
        ((is-type? 'do-let (car stmts))
         (**let (do-let-decls (car stmts))
               (desugar-do (cdr stmts))))
        ((null? (cdr stmts))
         (do-stmt-exp (car stmts)))                      ; last statement: bare exp
        (else
         (**app (**var/def (core-symbol ">>"))          ; e1 >> rest
                (do-stmt-exp (car stmts))
                (desugar-do (cdr stmts))))))

(define (desugar-do-bind stmt rest)
  (let ((pat (do-generator-pat stmt))
        (e1  (do-generator-exp stmt)))
    (if (failure-free-pattern? pat)
        (**app (**var/def (core-symbol ">>=")) e1
               (**lambda/pat (list pat) rest))
        (let ((v (make-temp-var "do")))
          (**app (**var/def (core-symbol ">>=")) e1
                 (**lambda/pat (list (**var-pat/def v))
                   (**case (**var/def v)
                     (list (**alt pat rest)
                           (**alt (**pat '_) (do-failure-exp))))))))))

;;; H98: pattern-match failure calls `fail' (a Monad method).
;;; 1.3/1.4: it calls `zero' (MonadZero).  This is THE feature seam.
(define (do-failure-exp)
  (if (feature? 'monad-fail)
      (**app (**var/def (core-symbol "fail"))
             (**string "pattern match failure in do expression"))
      (**var/def (core-symbol "zero"))))
```

> **Maintenance note:** a future dialect that changes `do` semantics (e.g. 1.4
> monad comprehensions) adds a feature to `*dialect-features*` and gates in
> `desugar-do`, never in the desugaring bodies. Invariants: the three
> equivalences above; pattern-match failure calls `fail`/`zero`.

---

## 6. LG-IO — abstract `IO`, `Main.main :: IO t`

**Status:** landed. `IO` is a `newtype` over the state-passing representation
(when `newtype` is on, the core symbol `IO` is an `algdata` — see
`core-symbols.mumble`'s `make-core-synonym-definition`); `instance Monad IO`
is in `lib/haskell98/prelude/PreludeIOMonad.hs`; primitives in
`src/runtime/io-primitives.mumble`.

The only code-bearing follow-up is preserving the **`thenIO` tail call** (also
relevant to BUG-4) and, post-M5, folding `IOError`/`ioError`/`catch` into the
Prelude from `IO.hs`:

```mumble
;;; src/runtime/io-primitives.mumble  (shape — thenIO MUST be a tail call)
(define (prim.thenIO io1 io2 state)
  (funcall (funcall io1 state) io2))   ; tail position: no frame kept
```

> **Follow-up (not code):** §6 open question "cost of an abstract IO" —
> measure before assuming the optimiser's IO-plumbing erasure is negligible.
> `catch` via Lisp non-local exit must interact correctly with lazily produced
> input (`getContents`); this is an open question to test, not yet code.

---

## 7. LG-NEWTYPE — `newtype`

**Status:** landed. Erased in `src/compiler/flic/ast-to-flic.mumble` and in
cfn pattern matching (`algdata-newtype?`); the `data-decl` struct carries a
`newtype?` slot; deriving runs after erasure, unchanged.

```mumble
;;; The one maintainable invariant: a newtype around a STRICT type must keep
;;; strictness.  ast-to-flic erases the wrapper but must thread the field's
;;; strictness annotation onto the underlying representation.
(define (newtype-representation alg)
  ;; Returns the single field's type, carrying its strictness flag so that
  ;; backend/strictness.mumble sees `newtype Age = Age !Int` as strict Int.
  (let ((con (car (algdata-constrs alg))))
    (car (constr-types con))))          ; the one field, with annotation
```

Invariants: `newtype Age = Age Int` shares `Int`'s runtime representation;
constructors are erased (no allocation); pattern matching on a newtype
constructor is a no-op at runtime.

---

## 8. LG-SHOW-READ — Text/Binary → Show/Read; drop `Bin`  *(M5 — active)*

The active milestone. **Prior dependency met:** constructor classes (so
`Show`/`Read` can be normal classes), `newtype` (so `IO` is an `algdata`),
monadic IO. Six steps, in dependency order.

### Step 1 — Gate derived Show/Read in `derived/text-binary.mumble`

The existing `text-fns` generates `Text` (`readsPrec`/`showsPrec`/
`readList`/`showList`). When `(feature? 'show-read)`, generate `Show` and
`Read` instead. `create-instance-fns` (in `derived-instances.mumble`) already
splits `text-fns`'s two-element list into Show (car) / Read (cadr), so the
cleanest change is a gated dispatcher:

```mumble
;;; src/compiler/derived/text-binary.mumble  (additions/replacements)

;;; Dispatch: Text (1.2) vs Show+Read (1.3+).  Returns a two-element list
;;; (show-side read-side) so create-instance-fns's car/cadr split is uniform.
(define (text-fns algdata suppress-reader?)
  (if (feature? 'show-read)
      (show-read-fns algdata suppress-reader?)
      (let ((print+read (if (algdata-enum? algdata)
                            (text-enum-fns algdata)
                            (text-general-fns algdata))))
        (when suppress-reader?
          (setf print+read (list (car print+read))))
        print+read)))

;;; Show + Read.  show-side = (showsPrec showList [show]) ; read-side = (readsPrec readList)
(define (show-read-fns algdata suppress-reader?)
  (let ((show-decls (show-fns algdata))
        (read-decls (if suppress-reader? '() (read-fns algdata))))
    (list show-decls read-decls)))
```

**Show** (`showsPrec`, `showList`, and `show` only when `show-method`):

```mumble
(define (show-fns algdata)
  (cons
   (**define '|showsPrec| '(|d| |x|)
     (**case/con algdata (**var '|x|)
       (lambda (con vars)
         (if (con-infix? con)
             (show-infix con vars)
             (show-prefix/show con vars)))))
   (if (feature? 'show-method)
       (list
        (**define '|show| '(|x|)
          (**app (**var/def (core-symbol "showsPrec"))
                 (**int 0) (**var '|x|) (**string ""))
                 ;; show x = showsPrec 0 x ""
                 ))
        (**define '|showList| '(|xs| |s|)
          (show-list-default (**var '|xs|) (**var '|s|))))
       (list
        (**define '|showList| '(|xs| |s|)
          (show-list-default (**var '|xs|) (**var '|s|)))))))
```

`show-list-default` is the Report default (`showChar '[' . shows x . showl …`,
with the special-case for `String` handled in `PreludeText`/`PreludeCore`, not
here).

**Read** (`readsPrec`, `readList`):

```mumble
(define (read-fns algdata)
  (list
   (**define '|readsPrec| '(|d| |str|)
     (if (algdata-enum? algdata)
         (read-enum algdata)
         (**append/l
          (map (lambda (con)
                 (if (con-infix? con) (read-infix con) (read-prefix con)))
               (algdata-constrs algdata)))))
   (**define '|readList| '(|str|)
     (read-list-default (**var/def (core-symbol "readsPrec")) (**var '|str|)))))
```

#### The nullary-constructor parenthesisation fix (also LG-DERIVING bug)

The current `show-prefix` (read in source) already guards nullary constructors
— but it gates on `(haskell98?)`, which is wrong for two reasons: it violates
invariant 2, and it does **not** fire in 1.3/1.4 Show mode (where `show-read`
is on but `haskell98?` is false). The fix is to gate on the *Show generation*,
not the dialect:

```mumble
;;; A nullary constructor is never parenthesised, in any dialect that
;;; generates Show (or Text-with-Show-shape).  Gate on what we generate,
;;; not on the dialect.
(define (show-prefix/show con vars)
  (if (null? vars)
      (**showString (**string (con-string con)))
      (**showParen
       (**<= (**int 10) (**var '|d|))
       (**dot/l (**showString (**string (con-string con)))
         (show-fields vars)))))

;;; Likewise readsPrec must not require parens around a nullary constructor.
(define (read-prefix-1 con)
  (let* ((arity (con-arity con))
         (vars (temp-vars "x" arity))
         (svars (cons '|rest| (temp-vars "s" arity))))
    (**let
     (list
      (**define '|readVal| '(|r|)
        (**listcomp
         (**tuple2 (**app/l (**con/def con) (map (function **var) vars))
                   (**var (car (reverse svars))))
         (cons
          (**gen `(tuple ,(con-string con) |rest|) (**lex (**var '|r|)))
          (read-fields vars svars (cdr svars)))))
     ;; Nullary (arity 0): readParen False; otherwise readParen (d > 9).
     (**readParen (if (eqv? arity 0) (**false) (**< (**int 9) (**var '|d|)))
                  (**var '|readVal|) (**var '|str|)))))
```

> **Ambiguity — `show` method vs function.** In 1.3/1.4 (`show-read` on,
> `show-method` off) `show` is a top-level function
> `show x = showsPrec 0 x ""`; in H98 (`show-method` on) `show` is a method
> of `Show` with that default.
> **Recommendation:** generate `show` as a method body iff `(feature? 'show-method)`,
> and *also* export a top-level `show` function in 1.3/1.4 (in `PreludeText`).
> The `**define '|show|` above is emitted only when `show-method` is on; the
> 1.3/1.4 top-level `show` lives in the Prelude (step 2). This keeps
> `tupleShowDict` (§RT-DICTLAYOUT) including `show` exactly when `show-method`
> is on — already the case in `tuple-prims.mumble`.

### Step 2 — Rewrite `lib/haskell98/prelude/PreludeText.hs` from `Text` to `Show`+`Read`

The class *declarations* move to `PreludeCore.hs` (step 3). `PreludeText.hs`
keeps `lex`, `readLitChar`, `showLitChar`, `showChar`, `showString`,
`showParen`, `readParen`, the top-level `reads`/`shows`/`read`, and (in
1.3/1.4) the top-level `show`. Constraints flip from `(Text a) =>` to
`(Show a) =>` / `(Read a) =>`:

```haskell
-- lib/haskell98/prelude/PreludeText.hs  (H98 shape)
module PreludeText (
        reads, shows, read,
        showChar, showString, readParen, showParen,
        readLitChar, showLitChar, lexLitChar, lex ) where

{-#Prelude#-}

import PreludeChar  (isSpace, isAlpha, isDigit, isAlphaNum, isUpper,
                     isOctDigit, isHexDigit, ord, chr)
import PreludeNumeric (lexDigits, readDec, readOct, readHex)
import PreludeArray (listArray, (!), assocs)

reads   :: (Read a) => ReadS a
reads   =  readsPrec 0

shows   :: (Show a) => a -> ShowS
shows   =  showsPrec 0

read    :: (Read a) => String -> a
read s  =  case [x | (x,t) <- reads s, ("","") <- lex t] of
            [x] -> x
            []  -> error "read{PreludeText}: no parse"
            _   -> error "read{PreludeText}: ambiguous parse"

-- `show' is a *method* of Show in H98 (show-method).  In 1.3/1.4 it is the
-- top-level function below; gated in the Prelude by the dialect feature.
-- show :: (Show a) => a -> String
-- show x = showsPrec 0 x ""

showChar    :: Char -> ShowS
showChar    =  (:)

showString  :: String -> ShowS
showString  =  (++)

showParen   :: Bool -> ShowS -> ShowS
showParen b p = if b then showChar '(' . p . showChar ')' else p

readParen   :: Bool -> ReadS a -> ReadS a
readParen b g = if b then mandatory else optional
  where optional r  = g r ++ mandatory r
        mandatory r = [(x,u) | ("(",s) <- lex r,
                               (x,t)   <- optional s,
                               (")",u) <- lex t    ]

-- lex, lexLitChar, readLitChar, showLitChar: unchanged from the H98 Report
-- (the existing PreludeText.hs already follows the Report; only the
-- Text/Show/Read constraint change above is new).
```

The bodies of `lex`/`lexLitChar`/`readLitChar`/`showLitChar` in the current
`PreludeText.hs` are already Report-correct and do not mention `Text`; they
are retained verbatim.

### Step 3 — Declare `Show`/`Read` as core classes in `PreludeCore.hs` (H98); keep `Text`/`Binary` for 1.2

```haskell
-- lib/haskell98/prelude/PreludeCore.hs  (class declarations, H98)

type  ReadS a = String -> [(a,String)]
type  ShowS   = String -> String

class  Show a  where
    showsPrec :: Int -> a -> ShowS
    show      :: a -> String
    showList  :: [a] -> ShowS

    show x         = showsPrec 0 x ""
    showList []    = showString "[]"
    showList (x:xs)= showChar '[' . shows x . showl xs
      where showl []     = showChar ']'
            showl (x:xs) = showChar ',' . shows x . showl xs

class  Read a  where
    readsPrec :: Int -> ReadS a
    readList  :: ReadS [a]

    readList = readParen False (\r -> [pr | ("[",s) <- lex r, pr <- readl s])
      where readl  s = [([],t)   | ("]",t)  <- lex s] ++
                       [(x:xs,u) | (x,t)    <- reads s, (xs,u) <- readl' t]
            readl' s = [([],t)   | ("]",t)  <- lex s] ++
                       [(x:xs,v) | (",",t)  <- lex s, (x,u) <- reads t,
                                                  (xs,v) <- readl' u]
```

The export list changes: `Text(...)` and `Binary(...)` leave the H98 export
list; `Show(showsPrec, show, showList)`, `Read(readsPrec, readList)` enter.
`Maybe`/`Either`/`Ordering`/`()` instances switch from `Text` to `Show`+`Read`
(their `readsPrec`/`showsPrec` bodies are identical; only the class head and
`readList`/`showList` defaults change).

### Step 4 — Drop `Binary`/`Bin`; `Num` and `Ix` lose the `Text` superclass

```haskell
-- Before (current, Yale modification): class (Eq a, Text a) => Num a where ...
--                                   class (Ord a, Text a) => Ix a where ...
-- After (H98 Report):
class  (Eq a, Show a) => Num a  where ...     -- was (Eq a, Text a)
class  (Ord a)        => Ix a   where ...     -- H98: Ix has only Ord
```

> `Ix` dropping `Text` (→ `Show`) is the H98 Report shape. The "Yale
> modification" `class (Ord a, Text a) => Ix a` existed so tuple `Ix`
> dictionaries could reuse `Text`; with Show/Read and data-driven dictionaries
> (§RT-DICTLAYOUT) that coupling is gone, so `Ix` becomes `class (Ord a) => Ix a`.

### Step 5 — Regenerate core symbols

`core-symbols.mumble` already wires `Show`/`Read` as feature-gated core names
via `*feature-core-names*` (verified in source):

```mumble
;;; src/compiler/top/core-symbols.mumble  (existing — already correct)
(define *feature-core-names*
  '((constructor-classes
     |Functor| |Monad| |MonadZero| |fmap| |>>=| |>>| |return| |fail| |zero|)
    (show-read |Show| |Read|)))
```

So `Show`/`Read` are core classes exactly when `(feature? 'show-read)`. The
remaining step 5 work is mechanical: run
`(generate-prelude-core-symbols)` (dumps `/tmp/prelude-syms`), diff, and paste
the refreshed symbol lists into `core-symbols.mumble` and `prelude-core-syms.mumble`.
No logic change — just regenerating the tables after steps 1–4.

### Step 6 — Remove `Assoc`/`Bin` from H98 core types (ties to BUG-7, §20)

```mumble
;;; src/compiler/top/core-definitions.mumble  (shape)
;;; Assoc and Bin are 1.2-only.  After show-read, Bin is gone from H98 entirely.
(define (h98-core-type? name)
  (and (not (memq name '(|Assoc| |Bin|)))
       (core-name-active? name)))
```

See BUG-7 (§20) for the full gating.

### Defaulting class list (mentioned in STRATEGY Where)

`src/compiler/tdecl/class.mumble`'s `find-class-kind` already lists `Show` and
`Read` among the `'Standard` classes (verified in source), so they already
participate in defaulting for H98 once they are core. No change needed beyond
confirming `Text`/`Binary` are not erroneously treated as standard for H98
defaulting — they are not, because `find-class-kind` keys off the actual
`core-symbol` objects, which for `Text`/`Binary` only exist as core in 1.2.

### Tests & invariants

`tests/haskell98/prelude/show-read.hs` derives `Show`+`Read`, `print`s and
`read`s values; `tests/haskell98/derived/derived-show.hs` checks nullary
constructors print without parens (flip the `.xfail` to pass). **1.2 must keep
using `Text`/`Binary`** — `lib/haskell-1.2/` is untouched. Derived `Show` for
records is deferred to LG-RECORDS. `tupleShowDict` includes `show` only when
`(feature? 'show-method)` (already true in `tuple-prims.mumble`).

---

## 9. LG-RECORDS — records  *(M6 — not started)*

Large; touches parser/ast/tdecl/type/cfn/derived/ie/scope. Prior dependency:
LG-SHOW-READ (derived `Show` for records uses field-label syntax).

### 9.1 AST: field labels on `constr`

```mumble
;;; src/compiler/ast/type-structs.mumble  (additions)

(define-struct field-label
  (slots
   (name  (type symbol))     ; the label, e.g. |px|
   (index (type fixnum))))   ; positional index into constr-types

;;; Extend constr:
(define-struct constr
  (include ast-node)
  (slots
   (constructor (type con-ref))
   (types (type (list (tuple type (list annotation-value)))))
   ;; Parallel to `types'; '() for a non-record constructor.
   (field-labels (type (list field-label)) (default '()))))
```

> **Ambiguity — labels on `constr` vs a `field-decl` struct.**
> **Recommendation: a `field-labels` slot on `constr`, parallel to `types`.**
> It reuses the existing positional `types` list (label `i` names `types[i]`),
> needs no new top-level decl form, and `ie.mumble` can treat a label as an
> exportable entity attached to its constructor with zero new struct plumbing.

### 9.2 Parser: record declarations, construction, update, patterns

Record construction/update/patterns use *existing* tokens (`{`, `}`, `=`), so
the lexer is untouched. The parser gains four productions. Pseudocode in
mumble-parser style (mirroring `decl-parser.mumble`/`exp-parser.mumble`'s
`token-case` idiom):

```mumble
;;; decl-parser: data C = C { f :: T, g :: U }
;;;   parses into a constr whose field-labels are (field-label f 0),(field-label g 1)
(define (parse-constr-with-fields con args-so-far)
  (token-case
   (\{ (parse-field-decls con))            ; -> constr with field-labels set
   (else (finish-ordinary-constr con args-so-far))))

;;; exp-parser: C { f = e, g = e }   (construction)
(define (parse-record-construction con-ast)
  (let ((fields (parse-field-assignments)))   ; alist (label-name . exp)
    (make record-con (con con-ast) (fields fields))))

;;; exp-parser: e { f = e, ... }     (update)
(define (parse-record-update e)
  (let ((fields (parse-field-assignments)))
    (make record-update (exp e) (fields fields))))

;;; pattern-parser: C { f = p, ... }
(define (parse-record-pattern con-ast)
  (let ((fields (parse-field-patterns)))
    (make record-pat (con con-ast) (fields fields))))
```

### 9.3 `tdecl`: generate selector functions

A field label `f` of constructor `C` at index `i` becomes a top-level function
`f :: C -> FieldType` that projects field `i`. Selectors are ordinary
functions, scoped to the defining module (so `C(..)` exports bring them in).

```mumble
;;; src/compiler/tdecl/tdecl-utils.mumble  (additions)

(define (generate-field-selectors alg)
  (let ((selects '()))
    (dolist (con (algdata-constrs alg))
      (do ((labels (constr-field-labels con) (cdr labels))
           (types  (constr-types con)        (cdr types))
           (i 0 (1+ i)))
          ((null? labels))
        (let* ((lab (car labels))
               (fname (field-label-name lab))
               (sel (make-new-var (symbol->string fname))))
          (push (tuple fname sel) selects)
          (add-field-selector-def sel alg con i
            (car (constr-type-at (car types)))))))
    (nreverse selects)))

;;; f x = case x of { C v0 .. vi .. vn -> vi }
(define (add-field-selector-def sel alg con i ftype)
  (let ((x (make-local-var "x"))
        (vars (temp-vars "v" (con-arity con))))
    (add-new-module-signature sel
      (**signature '()
        (**arrow (**tycon/def alg (algdata-tyvars alg))
                 ftype)))
    (add-new-module-def sel
      (**lambda/pat (list (**var-pat/def x))
        (**case (**var/def x)
          (list (**alt (**app-pat (**con/def con) (map (function **var-pat) vars))
                       (**var (list-ref vars i))))))))))
```

### 9.4 Type checking: construction, update, selection

```mumble
;;; src/compiler/type/expression-typechecking.mumble  (additions)

;;; Construction: infer the constructor from the label set, require ALL fields
;;; of that constructor present, then type-check positionally.
(define (type-check-record-con rc)
  (let* ((con (record-con-con rc))
         (alg (con-alg con))
         (labels (constr-field-labels con))
         (given (map (function car) (record-con-fields rc))))
    (check-all-fields-present con given labels)        ; error if missing/extra
    (let ((positional (order-fields-by-index (record-con-fields rc) labels)))
      (type-check (app con positional))))

;;; Update: e { f = v } has the SAME type as e.  Resolve the constructor from
;;; e's type; rebuild with field f overwritten.
(define (type-check-record-update ru)
  (let ((e-type (type-check (record-update-exp ru))))
    (let ((alg (ntycon-tycon (expand-ntype-synonym e-type))))
      (check-single-constructor-or-unambiguous alg (map car (record-update-fields ru)))
      ;; desugared in cfn (9.5); type-check the rebuilt application here
      (type-check (desugar-record-update ru alg e-type)))))
```

> **Ambiguity — partial update on multi-constructor types.** STRATEGY: "a type
> with multiple constructors cannot [update] (error if ambiguous)."
> **Recommendation:** allow record update only when *every* constructor of
> `alg` has the updated label (so the selector is total), or `alg` has one
> constructor. Otherwise `phase-error 'ambiguous-record-update`. This matches
> GHC's semantics and keeps the runtime selector total.

### 9.5 Closure conversion: record update desugars to full reconstruction

```mumble
;;; src/compiler/cfn/cfn.mumble  (addition)
;;; e { f = v }  ==>  \x -> C (overwrite field f with v, keeping the rest via selectors)
(define (desugar-record-update ru alg e-type)
  (let* ((con (car (algdata-constrs alg)))   ; single-constructor (9.4 ensured)
         (labels (constr-field-labels con))
         (updates (record-update-fields ru))
         (x (make-local-var "x")))
    (**lambda/pat (list (**var-pat/def x))
      (**app/l (**con/def con)
        (do ((labels labels (cdr labels))
             (i 0 (1+ i))
             (args '() (cons (field-arg x i labels updates) args)))
            ((null? labels) (nreverse args)))))))

;;; For field i: use the update value if this label is being updated,
;;; otherwise select the existing field from x.
(define (field-arg x i labels updates)
  (let ((lab (field-label-name (list-ref labels i)))
        (upd (assq lab updates)))
    (if upd
        (tuple-2-2 upd)
        (**app (**var/def (selector-for lab)) (**var/def x)))))
```

### 9.6 Record patterns

```mumble
;;; C { f = p }  ==>  C p0 p1 .. pn  (positional, wildcards for unnamed fields)
(define (desugar-record-pattern rp)
  (let* ((con (record-pat-con rp))
         (labels (constr-field-labels con))
         (by-name (record-pat-fields rp)))
    (**app-pat (**con/def con)
      (do ((labels labels (cdr labels))
           (i 0 (1+ i))
           (pats '()))
          ((null? labels) (nreverse pats))
        (let ((named (assq (field-label-name (car labels)) by-name)))
          (push (if named (tuple-2-2 named) (**pat '_)) pats))))))
```

### 9.7 Derived `Show` for records (blocked on this section; ties to LG-DERIVING)

```mumble
;;; src/compiler/derived/text-binary.mumble  (record branch of show-prefix/show)
;;; show (C {f = .., g = ..}) = "C {f = " ++ showsPrec 0 (f x) ++ ", g = " ++ ... ++ "}"
(define (show-prefix/record con vars labels)
  (**showParen
   (**<= (**int 10) (**var '|d|))
   (**dot/l
    (**showString (**string (string-append (con-string con) " {")))
    (show-record-fields vars labels))))
```

### Tests & invariants

`records-construction`, `records-update`, `records-pattern`, `records-export`,
`records-derived`, and failures `records-duplicate-field`, `records-missing-field`.
Invariants: selectors are ordinary functions `f :: C -> FieldType`; update
preserves the constructor/type; field labels are module-scoped and come in via
`C(..)`; derived `Show` uses brace syntax (H98 Report §10); plain datatype
syntax (no labels) is unaffected.

---

## 10. LG-QUALIFIED — qualified names, `import qualified … as`  *(M7 — not started)*

Prior dependency: none strictly, but it touches every name lookup, so it is
its own focused effort. Adds feature `qualified-names` (see §2).

### 10.1 Lexer: distinguish `M.name` from `a . b`

`.` always lexes as an operator today. The qualifier heuristic: an uppercase
identifier immediately followed by `.` *not followed by whitespace or another
operator char*, and followed by an identifier start, is a qualified name. This
requires one token of lookahead after the `.`.

```mumble
;;; src/compiler/parser/lexer.mumble  (addition in lex-conid, after scanning the conid)
(define (maybe-qualified conid-string)
  ;; Called with *char* just past the conid.  Emit a qualified token if the
  ;; next chars are  UpperId-or-LowerId-start  preceded by a non-trailing `.'.
  (if (and (feature? 'qualified-names)
           (char=? *char* #\.)
           (not (char-whitespace? *peek-char*))
           (char-case *peek-char*
             ((small large) '#t)
             (else '#f)))
      (begin
        (advance-char)                         ; consume '.'
        (let ((rest (scan-var-con)))
          (if (char-case (car (string->list conid-string)) (large '#t) (else '#f))
              ;; M.Con  -> qconid ; M.var  -> handled by caller as qvarid/qconid
              (emit-token/string 'qconid
                (string-append conid-string "." (list->string rest)))
              (emit-token/string 'qvarid
                (string-append conid-string "." (list->string rest))))))
      (emit-token/string 'conid conid-string)))
```

> **Ambiguity — qualifier detection.**
> **Recommendation: the "uppercase-start before `.`, no whitespace after `.`,
> identifier-start after `.`" rule.** It correctly distinguishes `Data.List.sort`
> (qualifier) from `(.) f g` (composition: `.` is parenthesised/standalone) and
> from `a . b` (whitespace around the operator). `Prelude.map` works once
> qualified import is on. Existing 1.2 code using `.` as composition is
> unaffected because `qualified-names` is off for 1.2.

### 10.2 AST & symbol table

Rather than a brand-new node, extend `var-ref`/`con-ref` with an optional
module qualifier, and make the symbol table two-level.

```mumble
;;; src/compiler/ast/ast.mumble  (addition)
;;;   var-ref, con-ref gain:  (qualifier (type (maybe symbol)) (default '#f))

;;; src/compiler/top/symbol-table.mumble  (two-level lookup)
;;; *modules* already maps module name -> module; each module has a
;;; symbol-table.  Qualified lookup is module -> name -> def.
(define (lookup-qualified mod-name name)
  (let ((mod (table-entry *modules* mod-name)))
    (if (eq? mod '#f)
        '#f
        (table-entry (module-symbol-table mod) name))))

(define (lookup-name name)
  ;; Unqualified: current module first, then imported (existing behaviour),
  ;; then a unique qualified candidate (else ambiguity error).
  (or (table-entry *symbol-table* name)
      (lookup-imported-unqualified name)
      (let ((cands (qualified-candidates name)))
        (cond ((null? cands) '#f)
              ((null? (cdr cands)) (car cands))
              (else (phase-error 'ambiguous-qualified
                      "Ambiguous occurrence ~A: it could refer to ~A."
                      name (map car cands)))))))
```

### 10.3 Import forms

`import qualified M` brings names in only as `M.name`. `import qualified M as N`
aliases the module. `import M (f, C(..))` brings `f`/`C` in unqualified *and*
keeps `M.f`/`M.C` available. The alias is recorded in the importing module's
import table:

```mumble
;;; src/compiler/import-export/ie.mumble  (addition)
;;; An import carries (module, as-name, qualified?, import-list).
(define (enter-qualified-import mod-name as-name)
  (setf (table-entry *module-aliases* as-name) mod-name))
```

### Tests & invariants

`qualified-import`, `qualified-as`, `qualified-mixed`, fail `qualified-ambiguous`,
`composition-still-works`. Invariants: `(.)` still parses as composition;
Prelude is always imported unqualified (and `Prelude.map` works if the feature
is on); 1.2 code unchanged (feature off); interface files round-trip qualified
names (invariant 7 — `backend/interface-codegen.mumble`,
`dump-interface.mumble`, `import-export/interface-parser.mumble` updated
together).

---

## 11. LG-IMPTEXP — H98 import/export semantics

**Status:** partial. Remaining: free `renaming`/`to`/`hiding`/`interface` as
identifiers in H98; enforce `T(..)` for synonym export and reject `T(non-constructor)`;
forbid redefinition of Prelude names.

### 11.1 Free the 1.2 import keywords in H98

The current `lex-varid` reserves `renaming`/`to`/`hiding`/`interface`
unconditionally. Free them when `(feature? 'h98-lexing)`:

```mumble
;;; src/compiler/parser/lexer.mumble  (modified lex-varid)
(define (lex-varid)
  (let ((sym (scan-var-con)))
    (cond
     ((and (feature? 'do-notation) (string=/list? sym "do"))     (emit-token '|do|))
     ((and (feature? 'newtype) (string=/list? sym "newtype"))    (emit-token '|newtype|))
     (else
      (parse-reserved sym varid
        ;; H98 frees these four words; 1.2 keeps them as import syntax.
        ,@(if (feature? 'h98-lexing)
              '("case" "class" "data" "default" "deriving" "else"
                "if" "import" "in" "infix" "infixl" "infixr" "instance"
                "let" "module" "of" "then" "type" "where")
              '("case" "class" "data" "default" "deriving" "else"
                "hiding"
                "if" "import" "in" "infix" "infixl" "infixr" "instance" "interface"
                "let" "module" "of"
                "renaming"
                "then" "to" "type" "where")))))))
```

### 11.2 Synonym/partial export enforcement

```mumble
;;; src/compiler/import-export/ie-utils.mumble  (additions)
(define (check-export-entity ent)
  (cond ((is-type? 'export-synonym ent)
         ;; A type synonym must be exported as T(..); T alone is meaningless.
         (phase-error 'synonym-needs-dots
           "Type synonym ~A must be exported as ~(~A(..)~)."
           (export-name ent) (export-name ent)))
        ((is-type? 'export-partial ent)
         ;; T(C1,...): every name in the list must be a constructor of T.
         (dolist (c (export-subnames ent))
           (unless (memq c (algdata-constr-names (export-def ent)))
             (phase-error 'not-a-constructor
               "~A is not a constructor of ~A." c (export-name ent)))))))
```

### 11.3 Forbid redefinition of Prelude names (H98)

```mumble
;;; src/compiler/import-export/ie.mumble  (addition)
(define (check-no-prelude-redef var)
  (when (and (feature? 'h98-lexing)
             (def-prelude? (table-entry *prelude-core-symbols* (def-name var))))
    (phase-error 'redefine-prelude
      "~A is a Prelude name and may not be redefined."
      (def-name var))))
```

Invariants: 1.2 retains `renaming` as import syntax; PreludeCore is always
implicitly imported (even `import Prelude hiding (...)`).

---

## 12. LG-DERIVING — Bounded, H98 Enum, Show/Read for records, nullary paren bug

**Status:** partial. Bounded + H98 Enum landed in `derived/ix-enum.mumble`.
Three remain.

### 12.1 Nullary-constructor parenthesisation

Fixed in §8.1 (`show-prefix/show` gates the nullary case on what is generated,
not on `(haskell98?)`). The same fix applies to the `Text` path: a nullary
constructor prints bare in every dialect.

### 12.2 Show/Read for records

Given in §9.7 (blocked on LG-RECORDS). Once records land, the record branch of
`show-prefix/show` produces `C { f = …, g = … }`.

### 12.3 Enum: verify the `Ord` superclass is dropped (H98)

```mumble
;;; src/compiler/derived/ix-enum.mumble  (verify; H98 Enum has NO Ord superclass)
(define (enum-fns alg)
  (if (feature? 'h98-lexing)
      (enum-fns/98 alg)        ; uses fromEnum/toEnum, no Ord dependency
      (enum-fns/1.2 alg)))     ; 1.2 Enum may assume Ord
```

`PreludeCore.hs` already declares `class Enum a where` (no `Ord` superclass)
for H98 — verified. Derived `Enum` must not emit an `Ord` constraint; the
`enum-fns/98` generator confirms this.

### Tests & invariants

`derive-all` (all six classes), `derive-show-nullary`, `derive-bounded-product`.
Invariants: derived instances match H98 Report §10 exactly; deriving works for
both `data` and `newtype`; derived `Eq`/`Ord` compare constructors in
declaration order.

---

## 13. LG-POLYREC — polymorphic recursion via signatures  *(M9)*

Prior dependency: LG-CCONSTRUCTOR (higher kinds, so `Nested [a]` type-checks).
Polymorphic recursion is undecidable without a signature; requiring one is
correct (H98 spec).

### 13.1 Dependency analysis: a signed binding is its own SCC

In `dependency-analysis.mumble`'s `restructure-decl-list`, a binding with an
explicit signature is generalised independently of its recursive partners
(SCC of size 1), even if it's mutually recursive with them. This is what lets
`f :: Nested a -> Int; f (Nest _ rest) = 1 + f rest` type-check (the recursive
call is at `Nested [a]`).

```mumble
;;; src/compiler/depend/dependency-analysis.mumble  (modified restructure-decl-list)
(define (restructure-decl-list decls)
  ;; ... existing Tarjan scaffold ...
  ;; CHANGE: before the visit loop, detach signed bindings from the mutual
  ;; recursion graph so each is solved alone.
  (dolist (decl decls)
    (let ((lhs (valdef-lhs decl)))
      (when (and (is-type? 'var-pat lhs)
                 (not (eq? (var-signature (var-ref-var (var-pat-var lhs))) '#f)))
        ;; A signed binding is its own SCC: it does not pull partners in,
        ;; though partners may still depend on it.
        (setf (valdef-signed? decl) '#t))))
  ;; The existing visit loop then pops a signed decl as a singleton group
  ;; (because its only self-edge, if any, is treated as non-recursive for
  ;; generalisation purposes: it generalises from the SIGNATURE, not the body).
  ...)
```

> **Ambiguity — how to detach.**
> **Recommendation: mark the signed binding and, in the SCC pop, emit a
> singleton `recursive-decl-group` whose generalisation uses the signature
> (§13.2) rather than the body.** This is the smallest change to the existing
> Tarjan walk; it does not alter the edge graph for *unsigned* bindings, so
> non-polymorphically-recursive code is unaffected (invariant).

### 13.2 Type checking: check the body against the signature, do not infer first

The existing `type-recursive` infers each body then reconciles with
signatures. For a signed polymorphically-recursive binding, the signature's
type variables must be instantiated as fresh *generic* variables and the body
checked against that — the body is allowed to be more specific (the recursive
call is at a more general type). `type-decl.mumble`'s
`generalize-overloaded-type` already does signature-driven generalisation for
non-recursive decls; the change is to take that path for signed recursive
groups:

```mumble
;;; src/compiler/type/type-decl.mumble  (modified type-recursive)
;;; For a signed group, instantiate the signature's tyvars as fresh generics,
;;; check the body against the instantiated signature, and generalise from the
;;; SIGNATURE (not the inferred body).  The recursive call may thus be at a
;;; more general type than the pattern -- polymorphic recursion.
(define (check-signed-recursive decl)
  (let* ((var (decl-var decl))
         (sig (var-signature var)))
    (mlet (((sig-type sig-vars) (instantiate-gtype/newvars sig)))
      ;; sig-vars are generic: the body may use var at instances of sig-type.
      (dolist (tv sig-vars) (setf (ntyvar-read-only? tv) '#t))
      (let ((body-type (type-decl-rhs decl)))
        (type-unify (remove-recursive-type body-type) sig-type
          (signature-mismatch var)))
      ;; Generalise from the signature, not body-type.
      (setf (var-type var) sig)
      sig-vars)))
```

### Tests & invariants

`poly-rec` (the `Nested` example), fail `poly-rec-no-sig`. Invariants:
non-polymorphically-recursive functions unchanged; the monomorphism restriction
still applies without a signature; explicit signatures are still *checked* (the
body must be an instance of the signature).

---

## 14. LG-MR2 — monomorphism restriction rule 2 (exported pattern bindings)

**Status:** bug. `find-exported-pattern-bindings` (verified in
`pattern-binding.mumble`) errors with "Can't export pattern binding" via
`(when (and (def-exported? var) (not (haskell98?))) (recoverable-error ...))`.
H98 rule 2: an exported *restricted* (pattern) binding is allowed but **not
generalised** — its type variables are defaulted at module end. The existing
`do-pattern-binding-rule` already appends the group's overloaded tyvars to the
non-generic list (the monomorphisation); the fix is to stop erroring and let
that monomorphisation stand, gated on a feature.

```mumble
;;; src/compiler/type/pattern-binding.mumble  (replacement for find-exported-pattern-bindings)
(define (find-exported-pattern-bindings decls)
  (dolist (decl decls)
    (dolist (var-ref (collect-pattern-vars (valdef-lhs decl)))
      (let ((var (var-ref-var var-ref)))
        ;; H98 (rule 2): an exported pattern binding is ALLOWED but not
        ;; generalised.  do-pattern-binding-rule has already moved its
        ;; overloaded tyvars onto the non-generic list, so they default at
        ;; module end.  Only error in 1.2, which lacks rule 2.
        (when (and (def-exported? var) (not (feature? 'mr2-export)))
          (recoverable-error 'exported-pattern-binding
            "Can't export pattern binding of ~A.~%" var-ref))
        ;; A pattern binding WITH a signature whose group needs generalisation
        ;; beyond the monomorphic type is still an error in both dialects.
        (when (not (eq? (var-signature var) '#f))
          (recoverable-error 'entire-group-needs-signature
            "Variable ~A signature declaration ignored.~%" var-ref))))))
```

```mumble
;;; src/compiler/top/globals.mumble  (add to *dialect-features*)
;;;   (mr2-export  haskell98 #f)   ; H98 rule 2: exported pattern bindings OK, monomorphic
```

> **Ambiguity — feature vs `(haskell98?)`.** The existing code gates on
> `(haskell98?)`. Invariant 2 says gate on a feature for new code.
> **Recommendation: add `mr2-export` to `*dialect-features*`** (held from
> `haskell98` onward) and gate on it, as above. MR2 is fundamentally an H98
> semantic, so a dedicated feature is cleaner than overloading `h98-lexing`
> (which is lexical). It also makes the 1.2 error path explicit and testable.

Invariants: rule 1 (no generalisation of pattern bindings) still holds; simple
(non-pattern) bindings unaffected; 1.2 behaviour unchanged (`mr2-export` off).

---

## 15. LG-DEFAULT — default `(Integer, Double)`

**Status:** landed. `system-init.mumble` sets H98 default `(Integer, Double)`,
1.2 `(Int, Double)`. Remaining issues are BUG-1/BUG-2 (§20).

```mumble
;;; src/compiler/top/system-init.mumble  (existing — verified)
(setf *standard-module-default*
      (make default-decl
        (types (list
                (**tycon/def (if (haskell98?)
                                 (core-symbol "Integer")
                                 (core-symbol "Int"))
                             '())
                (**tycon/def (core-symbol "Double") '())))))
```

> **Note:** this one `(haskell98?)` is *load-time image configuration*, not
> per-compile dialect switching (each image has one dialect, invariant 10), so
> it does not violate invariant 2 in spirit. The defaulting *algorithm* in
> `default.mumble` is feature-agnostic. BUG-1/BUG-2 (defaulting under a
> signature, Int wrap) are in §20.

---

## 16. LG-LOCALFIXITY … LG-RESERVED (the landed M2 wins)

All landed. Each is gated on a feature and is invisible to 1.2. Canonical
mechanism shown briefly; no new code needed.

- **LG-LOCALFIXITY** (`fixity-anywhere`): fixity decls accepted in any decl
  group; resolved in the `prec` phase so local fixity is visible during
  precedence resolution.
- **LG-HEX** (`h98-lexing`): `lex-numeric` already reads `0x1F`/`0o17` in both
  dialects (pure extension). Invariant: 1.2 lexes `0x1F` as `0` then `x1F`.
- **LG-TUPLECON**: `(,)`, `(,,)`, `(->)`, `[]` as constructors in
  `exp-parser`/`type-parser`.
- **LG-PARENLHS**: parenthesised operator LHS `(f . g) x = e` in `decl-parser`.
  Must not conflict with LG-QUALIFIED's `.` lookahead.
- **LG-LETCOMP**: `let` qualifiers in list comprehensions (`exp-parser`).
- **LG-STRICT**: `!` maps onto existing `{-#STRICT#-}` machinery
  (`decl-parser` + `type-structs` annotation + `backend/strictness.mumble`).
- **LG-PRAGMAS** (`h98-lexing`): `lex-pragma` skips unknown all-caps pragmas;
  Yale `STRICT`/`SPECIALIZE` still work.
- **LG-ARROW** (`h98-lexing`): `-->` lexes as an operator in H98, a comment in
  1.2 (verified in `lex-one-token`).
- **LG-HEADERLESS** (`headerless-main`): headerless module = `module Main(main) where`.
- **LG-RESERVED**: `do`/`newtype` reserved in all dialects ≥ 1.3 (gated on
  their features in `lex-varid`); `interface`/`renaming`/`to`/`hiding` freed
  in H98 (§11.1).

---

## 17. LG-UNICODE — Unicode `Char`  *(M9)*

Prior dependency: none. `*max-char*` is 255 (Latin-1) in `lexer.mumble`; char
primitives assume ASCII ≤ 255.

### 17.1 Full Unicode code points

```mumble
;;; src/compiler/parser/lexer.mumble  (change)
;;; The maximum Unicode code point.  Use the portable U+10FFFF rather than a
;;; host-specific char-code-limit so behaviour is identical across SBCL/ECL/ABCL.
(define *max-char* #x10FFFF)

(define (convert-num-to-char num)
  (cond ((and (>= num 0) (>= *max-char* num))
         (integer->char num))
        (else
         (signal-char-out-of-range num)
         '#\?)))
```

> **Ambiguity — `*max-char*` value.** SBCL's `char-code-limit` is large; using
> it directly would make `*max-char*` host-dependent and break the
> "1.2 must not break / portable across Lisps" goals.
> **Recommendation: `#x10FFFF`** (Unicode maximum) as a portable constant. The
> host merely needs to *support* that many characters; SBCL does. Latin-1
> (0–255) behaves identically to before (invariant).

### 17.2 UTF-8 source files

Source reading is host I/O. Confine the host-specific call to
`src/mumble/`/`src/runtime/` (invariant 3):

```mumble
;;; src/mumble/cl-support.lisp  (host-specific, SBCL)
(defun read-source-utf-8 (pathname)
  #+sbcl (sb-ext:octets-to-string
           (sb-ext:run-program '/bin/cat ...) ; -- or open with :external-format
           )
  ;; Portable shape: open the source file for the lexer with UTF-8 decoding.
  (open pathname :external-format :utf-8))
```

In practice the lexer's `lex-port` is handed a port already opened UTF-8 by the
driver; the lexer itself is charset-agnostic once `*max-char*` is raised.

### 17.3 Char primitives and predicates

`prim.ord`/`prim.chr` (`src/runtime/prims.mumble`) must round-trip full code
points (they already do on SBCL once `*max-char*` is raised). `lib/haskell98/Char.hs`
predicates (`isAlpha`, `isDigit`, …) are ASCII-only today; port Unicode-aware
versions from the H98 Report / Hugs (BSD, safe to copy with attribution —
invariant 8 forbids nhc98).

### Tests & invariants

`unicode-char` (use `ord 'λ'`, `chr 955`), `.xfail` until done. Invariants:
`ord 'A'` = 65; `chr 0` = `'\NUL'`; Latin-1 (0–255) identical to before.

---

## 18. Prelude and library gaps

Mostly tables in STRATEGY.md. The actionable code is the **superclass fix**
(`Num ⇐ Eq, Show`; `Ix ⇐ Ord`) which is LG-SHOW-READ step 4 (§8), already
shown. The remaining actionable items are system-library follow-ups.

### 18.1 IOError accessors and `try` (system library follow-ups)

```haskell
-- lib/haskell98/IO.hs  (additions)
ioeGetFileName  :: IOError -> Maybe FilePath
ioeGetHandle    :: IOError -> Maybe Handle
ioeGetErrorType :: IOError -> IOErrorType

try :: IO a -> IO (Either IOError a)
try m = catch (m >>= return . Right) (return . Left)
```

The `IOError` accessors require extending the IOError representation in
`src/runtime/io-errors.mumble` to carry the optional filename/handle
(currently it may not).

### 18.2 `BlockBuffering (Maybe Int)` buffering mode

```humble
-- lib/haskell98/IO.hs + src/runtime/handle-prims.mumble
data BufferMode = NoBuffering | LineBuffering
                | BlockBuffering (Maybe Int)
```

Add the third constructor to the buffering enum threaded through
`handle-prims.mumble`; map it onto SBCL's block-buffering where available.

### 18.3 Random follow-up

Switch `lib/haskell98/Random.hs` from compatibility names to
`minBound`/`maxBound`/`realToFrac` (drop the 1.2-era shims).

---

## 19. RT-DICTLAYOUT — generic tuple dictionaries

**Problem:** `src/runtime/tuple-prims.mumble` hard-codes dictionary layouts
and checks `(haskell98?)` to decide method counts (verified: `tupleOrdDict/l`
branches on `(haskell98?)` for `compare`). This blocks making `compare`/
`rangeSize` true methods and makes adding a dialect painful.

### 19.1 Data-driven `create-dict`

`create-dict` and `dict-super-slot` already compute superclass position from
`class-n-methods`/`class-super*`. The fix is to make the *method list*
data-driven too: read method names from the class definition rather than
listing them inline, and replace `(haskell98?)` with `(feature? ...)`.

```mumble
;;; src/runtime/tuple-prims.mumble  (rewritten tupleOrdDict/l)
(define (tupleOrdDict/l d)
  (let ((ord (core-symbol "Ord")))
    (create-dict-from-class ord d
      ;; methods are read from the class def in declaration order; the
      ;; compare method is present iff the class declares it (it does in H98).
      (class-method-vars ord)
      (list (tuple (core-symbol "Eq")
                   (tupleEqDict/l (class-dict-size (core-symbol "Eq"))
                                  (dict-super-slot (core-symbol "Eq")
                                                    (core-symbol "Eq"))))))))

;;; Generic: build the dict vector from the class's method list + super slots.
(define (create-dict-from-class class d method-vars super-dicts)
  (create-dict d
    (map (lambda (mv) (tuple-method-name class mv)) method-vars)
    super-dicts))
```

### 19.2 `tuple-super-dict-fn` as a table lookup

The current `tuple-super-dict-fn` is a `cond` over `Eq`/`Ord`/`Text`/`Show`.
Make it a table so a new class needs no edit here:

```mumble
(define *tuple-dict-fns* (make-table))
(define (register-tuple-dict-fn class-name fn)
  (setf (table-entry *tuple-dict-fns* class-name) fn))
(register-tuple-dict-fn (core-symbol "Eq")    (function tupleEqDict/l))
(register-tuple-dict-fn (core-symbol "Ord")   (function tupleOrdDict/l))
(register-tuple-dict-fn (core-symbol "Show")  (function tupleShowDict/l))
(register-tuple-dict-fn (core-symbol "Read")  (function tupleReadDict/l))
(register-tuple-dict-fn (core-symbol "Text")  (function tupleTextDict/l))   ; 1.2
(register-tuple-dict-fn (core-symbol "Bounded")(function tupleBoundedDict))

(define (tuple-super-dict-fn class)
  (let ((fn (table-entry *tuple-dict-fns* class)))
    (if (eq? fn '#f)
        (error "No tuple dictionary for superclass ~A" class)
        fn)))
```

### 19.3 Replace `(haskell98?)` with `(feature? ...)`

`tupleShowDict/l` already gates `show` on `(feature? 'show-method)` (verified).
Apply the same to `tupleOrdDict/l`'s `compare` decision: `compare` is a method
iff the H98 `Ord` declares it — which the data-driven version (19.1) handles
automatically by reading `class-method-vars`, so the `(haskell98?)` check
disappears entirely.

> **Ambiguity — runtime feature? vs build-time generation.** STRATEGY offers:
> (a) data-driven `create-dict` with `(feature? ...)` at runtime, or (b)
> generate per-dialect tuple-dict functions at prelude build time.
> **Recommendation: (a) data-driven + `feature?`.** It is the smaller change,
> keeps a single runtime image story (invariant 10 — dialect is fixed at
> build, so `feature?` is constant per image and effectively free), and
> `dict-super-slot` already does the positional work. Option (b) is a later
> optimisation if dictionary construction shows up in profiles.

### Tests & invariants

`tuple-eq-ord`, `tuple-show`; all 1.2 tuple tests regress-clean. Invariants:
`dict-super-slot` computes position from the class def (not a hardcoded
offset); adding a Prelude method does not break existing layouts; 1.2
Text/Binary tuple dicts still work.

---

## 20. Open bugs

### BUG-1 — no defaulting under an expression signature

`show (2 ^ 2 :: Int)` is "ambiguous"; `round 2.5` (only `RealFrac`) not
defaulted. Defaulting doesn't fire when the ambiguity is under an explicit
expression signature. After type-checking an expression with a signature,
apply defaulting to residual ambiguous tyvars that are in defaulting classes.

```mumble
;;; src/compiler/type/default.mumble  (hook) + expression-typechecking.mumble
;;; After unifying a signature-annotated expression, sweep its residual context
;;; for defaultable ambiguous tyvars and default them.
(define (default-after-signature sig-type def)
  (dolist (tyvar (collect-tyvars sig-type))
    (when (and (ntyvar-context tyvar)
               (defaultable-context? (ntyvar-context tyvar)))
      (maybe-default-ambiguous-tyvar tyvar def *module*))))

(define (defaultable-context? classes)
  (every (lambda (c) (memq (class-kind c) '(numeric Standard))) classes))
```

> **Ambiguity — where to invoke.** The cleanest hook is at the end of the
> signature-checking path in `expression-typechecking.mumble` (after
> `check-var-signature`-style unification for expression signatures), calling
> `default-after-signature` with the residual context.
> **Recommendation: invoke it there**, reusing the existing
> `maybe-default-ambiguous-tyvar` + `find-default-type` machinery (verified in
> `default.mumble`) so the default *list* (per-module `*default-decls*`) is
> honoured. Test: remove `.xfail` from `default-in-annotation` and
> `default-realfrac`.

### BUG-2 — `Int` wraps silently; default `(Int, Double)` in some paths

Verify the H98 default is `(Integer, Double)` in *all* code paths. The
`system-init` conditional (§15) sets it correctly at image build; audit that
no other path seeds `*default-decls*` with `(Int, …)` for H98. `Int` wrap is
SBCL behaviour — document it (or add overflow detection, lower priority).

### BUG-3 — MR rule 2 (exported pattern binding)

= LG-MR2, §14.

### BUG-4 — shallow control stack

Non-tail recursion over 100 000 elements overflows. Two prongs:

```makefile
# Makefile — raise the saved-image control stack
STACK_MB ?= 1024   # was 512
```

and restructure deeply-recursive runtime primitives to be iterative/tail-recursive
(preserving the `thenIO` tail-call invariant from §6). No source code change is
*required* to clear the xfail beyond raising `STACK_MB`; the iterative-rewrite
is the durable fix.

### BUG-5 — batch mode diagnostics + extra newline

Root cause (verified): `system-init.mumble` sets
`(setf *error-output-port* (current-output-port))` — i.e. **stdout** — so
diagnostics go to stdout in every mode. Additionally, after a compile error
the driver continues (printing "The variable #:|mainNNNN| is unbound"), and
`apply-exec` emits a separator newline.

```mumble
;;; src/compiler/top/system-init.mumble  (fix: stderr in batch mode)
(setf *error-output-port*
      (if *haskell-batch-mode*
          (current-error-port)        ; diagnostics to stderr in batch runs
          (current-output-port)))     ; REPL keeps diagnostics on stdout

;;; src/compiler/command-interface/incremental-compiler.mumble
;;; After a compile error, stop instead of evaluating an unbound main.
(define (run-program name)
  (if (compile/load name)
      (let ((main-var (table-entry
                        (module-symbol-table (table-entry *modules* '|Main|))
                        '|main|)))
        (if main-var
            (begin (apply-exec main-var) '#t)
            (error "Variable main missing")))
      '#f))   ; compile failed: do NOT fall through to evaluation
```

> **Ambiguity — the `apply-exec` newline.** The visible
> `(when (not *haskell-batch-mode*) (say "~%"))` already guards batch mode, so
> the stray newline in `.stdout` files is likely from a *different* path
> (e.g. a prompt/flush in the interactive driver leaking into captured output).
> **Recommendation:** audit every `terpri`/`fresh-line`/`say` in the
> command-interface for a `*haskell-batch-mode*` guard, then regenerate all
> `.stdout` expectations without the trailing newline and add `tests/haskell98/fail/`
> cases with `.exit` files for non-zero exits.

### BUG-6 — datatype contexts not enforced

`data Eq a => Set a = …` parses but the context is ignored. Thread the
`data-decl` context onto each constructor so constructing a value adds the
context's constraints. `data-decl` already has a `context` slot (verified in
`type-structs.mumble`).

```mumble
;;; src/compiler/tdecl/tdecl.mumble  (attach context to constructors)
(define (attach-datatable-context decl)
  (let ((ctx (data-decl-context decl)))
    (when (not (null? ctx))
      (dolist (con (algdata-constrs (data-decl-simple decl)))
        (setf (con-context con) ctx)))))

;;; src/compiler/type/expression-typechecking.mumble
;;; Constructing C v1..vn where C's data-decl had context Ctx adds Ctx.
(define (type-check-con-application con arg-types)
  (let ((result (apply-constructor con arg-types)))
    (if (con-context con)
        (add-context (instantiate-context (con-context con) arg-types)
                     result)
        result)))
```

> **Note:** H98 *deprecates* datatype contexts; H2010 removes them. Low
> priority. **Recommendation: enforce (add the constraints) but emit a
> `haskell-warning 'datatype-context-deprecated`** — enforcing is better than
> silently ignoring, and the warning nudges users off the feature.

### BUG-7 — `Assoc`/`Bin` are compiler core types

H98 programs cannot define `Assoc`/`Bin` because they're wired into core.
Remove from H98 core, gate on dialect. After Show/Read (§8 step 6), `Bin` is
gone from H98 entirely.

```mumble
;;; src/compiler/top/core-definitions.mumble
;;; Assoc and Bin are core only in 1.2.  In H98 they are ordinary names.
(define (h98-core-type? name)
  (not (memq name '(|Assoc| |Bin|))))

;;; In create-core-globals, skip wiring Assoc/Bin as prelude-core when
;;; (feature? 'show-read) (H98+).
(define (make-core-bin-definition name pc?)
  (if (feature? 'show-read)
      (make-ordinary-definition name)        ; H98: Bin is a user-definable name
      (make-core-type-definition name pc?))) ; 1.2: Bin stays core
```

Test: remove `.xfail` from `prelude-names-free`.

### BUG-8 — case-insensitive filesystem unit-file collision

`foo.hs` beside `Foo.hu` picks up the wrong unit file on macOS. Be
case-sensitive in module-name matching regardless of the filesystem:

```mumble
;;; src/compiler/csys/compiler-driver.mumble  (module lookup)
(define (find-unit-file module-name)
  ;; Match the module name case-sensitively even on case-insensitive FSes.
  (let ((candidates (directory-files (unit-dir) (string-append module-name ".hu"))))
    (find-if (lambda (f) (string=? (basename f) (string-append module-name ".hu")))
             candidates)))
```

Optionally warn on a case-fold collision (`foo.hs` vs `Foo.hs`).

### BUG-9 — flaky prolog test

`tests/haskell-1.2/demo/prolog` failed once under `-j 8`, not reproduced since.
Likely a race/shared resource in the runner. **Monitor; no code action unless
it recurs.**

---

## 21. Cross-cutting invariants (checklist — no code)

Encode these as a pre-commit checklist; they are not implementable functions
but govern every change above.

1. **Keep the architecture.** No rewriting the compiler in Haskell. Pipeline
   order and phase boundaries are sacred.
2. **Gate on features, not dialects.** `(feature? 'name)`; add to
   `*dialect-features*`; never raw `(haskell98?)` for new code.
3. **Host-specific code stays in `src/mumble/` and `src/runtime/`.** No bare
   `sb-ext:`/`sb-sys:` elsewhere; use `#+sbcl` with portable fallbacks.
4. **Generated Lisp keeps readable names** (module + identifier, not gensyms)
   so `sb-sprof` maps back to source.
5. **Every language change needs a test** (`.hs` + `.stdout`/`.exit` under
   `tests/<dialect>/`); `make test` before commit.
6. **1.2 must not break.** Feature-gated changes are invisible to 1.2.
7. **Interface files (`.hu`) must round-trip.** Any type/kind/qualified-name
   change updates `interface-codegen.mumble`, `dump-interface.mumble`, and
   `import-export/interface-parser.mumble` *together*.
8. **Don't copy from nhc98** (licence). H98 Report code and Hugs (BSD) are
   safe with attribution.
9. **Dictionary layout is computed from class definitions, not hardcoded.**
   `dict-super-slot` + `class-n-methods` drive positions.
10. **`*haskell-dialect*` is set at image-build time** via `$PRELUDE`. One
    dialect per saved image; do not switch at runtime.

---

## 22. Milestone ordering

No implementation code. Critical path M3 → M4 → **M5 (active)** → M6 → M7.
M3/M4 done. This document supplies the reference code to complete M5
(§8), then M6 (§9) and M7 (§10), with M9 items (§4 kind inference, §13
polymorphic recursion, §17 Unicode) available once their prerequisites land.
