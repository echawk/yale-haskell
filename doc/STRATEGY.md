# Yale Haskell — Implementation Strategy for Agents

This document is a high-level, actionable guide for any agent (human or
LLM) implementing a feature or fixing a gap on the road to Haskell 98
(and beyond).  It is derived from [REVIVAL-PLAN.md](REVIVAL-PLAN.md) but
goes further: for every gap it names **where** to change the real source,
**how** to approach it, gives an **example**, suggests **tests**, and
lists **invariants** that must not break.

**Do not modify source code based on this document alone** — it is a
planning artifact.  Read the cited source files first, then implement.

## How to use this document

- Each entry has a stable ID (e.g. `LG-RECORDS`).
- **Status** reflects the state after §9 of the revival plan
  (2026-10-06): constructor classes, `do`, `newtype`, and monadic IO
  have landed on the `constructor-classes` branch.
- **Where** gives real file paths under `src/compiler/` (or `src/runtime/`,
  `lib/`).  Paths are verified against the current tree.
- **Tests** follow the convention in [`tests/run-tests`](../tests/run-tests):
  a `.hs` file with a `.stdout` (expected output) or `.exit` (expected
  status) companion, optionally a `.stdin` and a `.xfail` (expected
  failure note).  Tests live under `tests/<dialect>/` (`haskell98/` or
  `haskell-1.2/`).  Run with `make test` or `tests/run-tests -v`.

---

## Pipeline reference

```
parse → import/export → tdecl → derived → prec/scope → depend → type
     → cfn → flic → optimize → strictness → codegen → Lisp
```

| Phase | Directory | Key files |
|---|---|---|
| Parse | `src/compiler/parser/` | `lexer.mumble`, `token.mumble`, `module-parser.mumble`, `exp-parser.mumble`, `decl-parser.mumble`, `type-parser.mumble`, `pattern-parser.mumble` |
| Import/export | `src/compiler/import-export/` | `ie.mumble`, `ie-utils.mumble`, `ie-errors.mumble` |
| Type decls | `src/compiler/tdecl/` | `tdecl.mumble`, `class.mumble`, `instance.mumble`, `tdecl-utils.mumble` |
| Derived | `src/compiler/derived/` | `derived.mumble`, `derived-instances.mumble`, `eq-ord.mumble`, `ix-enum.mumble`, `text-binary.mumble` |
| Precedence/scope | `src/compiler/prec/` | `prec.mumble`, `prec-parse.mumble`, `scope.mumble` |
| Dependency analysis | `src/compiler/depend/` | `depend.mumble`, `dependency-analysis.mumble` |
| Type checking | `src/compiler/type/` | `type.mumble`, `type-main.mumble`, `unify.mumble`, `dictionary.mumble`, `type-decl.mumble`, `pattern-binding.mumble`, `expression-typechecking.mumble`, `predicates.mumble`, `type-vars.mumble`, `default.mumble` |
| Closure conversion | `src/compiler/cfn/` | `cfn.mumble` |
| FLIC (intermediate) | `src/compiler/flic/` | `flic.mumble`, `flic-structs.mumble`, `flic-walker.mumble`, `ast-to-flic.mumble` |
| Optimize | `src/compiler/backend/` | `optimize.mumble`, `strictness.mumble`, `box.mumble` |
| Codegen | `src/compiler/backend/` | `codegen.mumble`, `interface-codegen.mumble`, `dump-interface.mumble` |
| Top-level / globals | `src/compiler/top/` | `globals.mumble`, `symbol-table.mumble`, `system-init.mumble`, `prelude-core-syms.mumble`, `core-symbols.mumble`, `core-definitions.mumble`, `core-init.mumble` |
| Runtime | `src/runtime/` | `runtime.mumble`, `prims.mumble`, `tuple-prims.mumble`, `io-primitives.mumble`, `io-errors.mumble`, `handle-prims.mumble`, `system-prims.mumble`, `array-prims.mumble` |
| Command interface | `src/compiler/command-interface/` | `incremental-compiler.mumble`, `command.mumble`, `command-interface.mumble` |
| Driver | `src/compiler/csys/` | `compiler-driver.mumble`, `csys.mumble` |

### Dialect gating

All dialect differences are gated through the feature table in
`src/compiler/top/globals.mumble`:

```mumble
(define *dialect-order* '(haskell-1.2 haskell-1.3 haskell-1.4 haskell98))
(define *dialect-features*
  '((constructor-classes haskell-1.3 #f)
    (do-notation         haskell-1.3 #f)
    (newtype             haskell-1.3 #f)
    (show-read           haskell-1.3 #f)
    (show-method         haskell98 #f)
    (monad-fail          haskell98 #f)
    (h98-lexing          haskell98 #f)
    (headerless-main     haskell98 #f)
    (fixity-anywhere     haskell98 #f)))
```

Check a feature with `(feature? 'name)`.  **Never** use raw `(haskell98?)`
for new code — add a feature to this table instead.  The dialect is
selected at image-build time via the `$PRELUDE` environment variable
pointing at `lib/<dialect>/prelude`.

---

## Status summary

**Landed (verified in source):**
- Constructor classes & higher kinds (`tyapp`/`ntyapp`, `unify-app-con`,
  `unify-apps`, `ntyvar-app-contexts`)
- `do` notation (desugared in `prec/scope.mumble`, `do-failure-exp`)
- `newtype` (erased in `ast-to-flic.mumble`, `cfn.mumble`)
- Monadic IO (`IO` as newtype, `instance Monad IO`, `PreludeIO`)
- All M2 cheap wins: hex/octal, `(,)` constructors, parenthesised LHS,
  `let` in comprehensions, `!` fields, H98 pragmas, `-->`, headerless
  Main, local fixity, reserved words
- Defaulting `(Integer, Double)` for H98 (conditional in `system-init.mumble`)
- C-T rule dropped for H98 (`tdecl/instance.mumble`)
- Partial exports, synonym exports
- Bounded/Enum deriving (`derived/ix-enum.mumble`)
- System libraries: List, Char, Numeric, Ratio, Complex, Ix, Array,
  System, CPUTime, Directory, Time, Locale, Random, IO

- Show/Read split (M5): H98 Prelude has `Show`/`Read`; `Text`, `Binary`
  and `Bin` are gone from H98 (`*feature-retired-names*` in
  `top/core-symbols.mumble`); derived Show/Read use Report precedences

- Records (M6): field declarations, selectors, construction, update,
  record patterns, `C {}`, derived Show/Read, `T(C, f)` export lists;
  translated in the scope phase (`prec/scope.mumble`), feature `records`

- Qualified names (M7): `M.x`, `M.C`, `M.+` tokens, `import qualified M
  as N`, `Main.f`, `Prelude.x`; feature `qualified-names`

**Remaining major work:**
- `LG-POLYREC` — Polymorphic recursion (M9, not started)
- `LG-UNICODE` — Unicode Char (M9, not started)
- Various open bugs (see §Open Bugs)

---

## Language gaps (detailed)

### LG-CCONSTRUCTOR: Constructor classes, higher kinds, kind inference

**Status:** ✅ Landed (§9).  Documented here for maintenance and the
remaining gap: **kind inference is absent**.

**Where:**
- AST: `src/compiler/ast/type-structs.mumble` — `tyapp` struct
  (`fun` is always a `tyvar`; `tycon` applications with fewer args than
  arity are represented as `tycon`).
- Unifier: `src/compiler/type/unify.mumble` — `unify-app-con` (binds a
  type-variable head to a partially applied tycon), `unify-apps`
  (unifies two `tyapp`s), `propagate-contexts/app` (defers constraints
  on `f a` until `f` is instantiated).
- Instance lookup: `src/compiler/type/dictionary.mumble` —
  `process-placeholder` handles `ntyapp?` via `signal-unresolved-app-constraint`;
  `generate-dict-ref` emits `dict-placeholder`s for non-generic apps.
- Instance registration: `src/compiler/tdecl/instance.mumble` —
  `lookup-instance` (line ~142, ~258, ~276).

**Remaining gap — kind inference:**
- There is no kind checker.  A kind mismatch surfaces as an
  arity/unification error (see `unify-args`: "kind mismatch" message).
- **Where to add it:** A kind-inference pass in `src/compiler/tdecl/`
  (new file, e.g. `kind-inference.mumble`), called after `tdecl` and
  before `type`.  Kinds would be `*` and `k1 -> k2`.  Alternatively,
  augment `type-structs.mumble` with a `kind` slot on `tyvar`/`tycon`.
- **Example:** `data Maybe a = Nothing | Just a` gives `Maybe :: * -> *`.
  `data GRose f a = GNode a (GRose f (f a))` requires `f :: * -> *`.
  Today the second would fail with an obscure unification error.
- **Test:** `tests/haskell98/language/higher-kinds.hs` — define
  `GRose`, construct a value, print it.  Add a `.xfail` for
  nested higher-kinded recursion if unsupported.
- **Invariants:**
  - Existing `Maybe`, `Either`, `[]`, `(->)` instances must continue to
    type-check.
  - Partially applied instance heads (`Maybe`, `Either e`, `(->) r`)
    must still resolve.
  - Interface files (`.hu`) must serialise kinds if added (see
    `backend/interface-codegen.mumble` and `backend/dump-interface.mumble`).

---

### LG-DO: `do` notation

**Status:** ✅ Landed (§9).

**Where:**
- Lexing: `src/compiler/parser/token.mumble` (line 15: `do` is a layout
  keyword) and `src/compiler/parser/lexer.mumble`.
- Desugaring: `src/compiler/prec/scope.mumble` (lines 394–452):
  `desugar-do`, `desugar-do-bind`, `do-failure-exp`.
  - `desugar-do-bind` checks `failure-free-pattern?`; if the pattern is
    failure-free, it generates `e >>= \p -> rest`; otherwise it generates
    a `case` with `fail` (H98) or `zero` (1.3/1.4).
- Failure: `do-failure-exp` gates on `(feature? 'monad-fail)` — H98 uses
  `fail` (a Monad method), 1.3/1.4 use `zero` (MonadZero).

**Maintenance notes:**
- If adding a new dialect that changes `do` semantics (e.g. monad
  comprehensions for 1.4), add a feature predicate and gate in
  `desugar-do`.
- **Invariants:**
  - `do { x <- e1; e2 }` ≡ `e1 >>= \x -> e2`
  - `do { e1; e2 }` ≡ `e1 >> e2`
  - `do { let p = e; rest }` ≡ `let p = e in do { rest }`
  - Pattern-match failure in a generator calls `fail`/`zero`.

---

### LG-IO: Abstract `IO`, `Main.main :: IO t`

**Status:** ✅ Landed (§9).

**Where:**
- `IO` is a `newtype` over the state-passing representation.  When the
  dialect has `newtype`, the core symbol `IO` is created as a data type.
- `instance Monad IO` lives in `lib/haskell98/prelude/PreludeIOMonad.hs`.
- `IOError`, `ioError`, `catch`, `putStr`… live in
  `lib/haskell98/prelude/PreludeIO.hs`.
- IO primitives: `src/runtime/io-primitives.mumble`,
  `src/runtime/io-errors.mumble`, `src/runtime/handle-prims.mumble`.
- `Main.main` checking: `src/compiler/command-interface/incremental-compiler.mumble`.

**Remaining work (M4 follow-up):**
- The optimiser currently may erase IO plumbing.  §6 open question: "cost
  of an abstract IO."  Measure before assuming it's negligible.
- Unify I/O: when M5 completes, the Prelude takes over `IO.hs`'s
  `IOError`/`ioError`/`userError`/`catch`, and Prelude I/O is rebuilt on
  the handle primitives (see §7 "Recommended next steps").

**Invariants:**
- `thenIO` tail-call optimisation must be preserved (critical for
  non-overflowing IO loops — see open bug 4).
- `catch` via Lisp non-local exit must interact correctly with lazily
  produced input (`getContents`) — open question, §6.

---

### LG-NEWTYPE: `newtype`

**Status:** ✅ Landed (§9).

**Where:**
- Erasure in `src/compiler/flic/ast-to-flic.mumble` and in cfn pattern
  matching (`algdata-newtype?`).
- The `data-decl` struct has a `newtype?` slot
  (`ast/type-structs.mumble`).
- Deriving works unchanged (the `newtype` is erased before deriving runs).

**Maintenance notes:**
- Ensure `newtype` erasure doesn't break strictness analysis
  (`backend/strictness.mumble`) — a `newtype` around a strict type should
  retain strictness.
- **Invariants:**
  - `newtype Age = Age Int` has the same runtime representation as `Int`.
  - `newtype` constructors are erased (no allocation).
  - Pattern matching on a `newtype` constructor is a no-op at runtime.

---

### LG-SHOW-READ: Text/Binary → Show/Read; drop `Bin`  *(M5)*

**Status:** ✅ Landed (2026-10-07).  The notes below describe the original
plan; step 5 (regenerating core symbols) proved unnecessary — the 1.2
names are switched off per dialect by `*feature-retired-names*`.
`Assoc` remains a (hidden) core type (BUG-7).

**Where:**
- Derived instances: `src/compiler/derived/text-binary.mumble` —
  currently generates `Text` (readsPrec/showsPrec/readList/showList).
  Must switch to generating `Show` + `Read` when `(feature? 'show-read)`.
- Tuple dictionaries: `src/runtime/tuple-prims.mumble` —
  `tupleShowDict`/`tupleReadDict` already exist (lines showing
  `prim.tupleShowDict`, `prim.tupleReadDict`); `tupleTextDict` and
  `tupleBinaryDict` remain for 1.2.
- Core symbols: `src/compiler/top/core-symbols.mumble` and
  `src/compiler/top/core-init.mumble` — `Text` is currently a core class.
  `Show` and `Read` must become core classes for H98; `Text` and `Bin`
  stay for 1.2.
- Defaulting class list: `src/compiler/tdecl/class.mumble` — the list of
  classes that participate in defaulting.  Must include `Show`/`Read`
  instead of `Text` for H98.
- Prelude: `lib/haskell98/prelude/PreludeText.hs` currently defines
  `Text`.  Must be rewritten to define `Show` and `Read`.
  `lib/haskell98/prelude/PreludeCore.hs` declares `Text` as a core class;
  change to `Show`/`Read`.
- The `show` method: feature `show-method` (H98 only).  In 1.2, `show`
  is a function, not a method, so it **cannot** be a core symbol for 1.2.

**Approach:**
1. Gate derived Show/Read generation on `(feature? 'show-read)` in
   `derived/text-binary.mumble`.  Generate `showsPrec`/`show`/`showList`
   for Show and `readsPrec`/`readList` for Read.
2. Rewrite `PreludeText.hs` from `Text` to `Show` + `Read`.
3. Update `PreludeCore.hs`: declare `Show` and `Read` as core classes
   (H98), keep `Text`/`Binary` for 1.2.
4. Drop `Binary`/`Bin` from H98 (`Num` and `Ix` lose their `Text`
   superclass).
5. Regenerate core symbols: `src/compiler/top/prelude-core-syms.mumble`
   (`generate-prelude-core-symbols` dumps to `/tmp/prelude-syms`; paste
   into `core-symbols.mumble`).
6. Remove `Assoc` and `Bin` from compiler core types (open bug 7).

**Example:**
```haskell
-- Before (1.2): class (Eq a) => Text a where ...
-- After (H98):
class Show a where
  showsPrec :: Int -> a -> ShowS
  show      :: a -> String
  showList  :: [a] -> ShowS

class Read a where
  readsPrec :: Int -> ReadS a
  readList  :: ReadS [a]
```

**Tests:**
- `tests/haskell98/prelude/show-read.hs` — derive `Show` and `Read` for
  a datatype, `print` and `read` values, compare output.
- `tests/haskell98/derived/derived-show.hs` — nullary constructors must
  not be parenthesised (open bug: `derived-show`).
- `.xfail` removal: the `derived-show` xfail should flip to pass.
- Regression: all 1.2 tests must still pass (they use `Text`).

**Invariants:**
- 1.2 mode must continue to use `Text`/`Binary` — no breaking changes
  to `lib/haskell-1.2/`.
- `show` is a method only in H98 (`show-method` feature); in 1.3/1.4 it
  is a top-level function.
- Derived `Show` for records (once records land) must use field-label
  syntax.
- Dictionary layout: `tupleShowDict` must include `show` only when
  `(feature? 'show-method)` (already handled in `tuple-prims.mumble`).

---

### LG-RECORDS: Records (construction, update, selection, patterns)  *(M6)*

**Status:** ✅ Landed (2026-10-07).  As built, unlike the plan below:
record expressions and patterns are *translated* in the scope phase
(Report 3.15's translation), so the type checker and cfn are untouched;
labels are `constr-field-labels` (parser) and `con-field-labels` (vars,
per argument); a field's selector var has `var-field-alg`; selectors are
generated in `tdecl/alg-syn.mumble`; both are dumped in interfaces.  The
plan's notes are kept for reference.

**Where (all need changes):**
- **Lexer:** `src/compiler/parser/lexer.mumble` — no changes needed for
  syntax (records use existing tokens), but the parser must handle
  field-label syntax.
- **Parser:** `src/compiler/parser/decl-parser.mumble` (datatype decls
  with field labels), `src/compiler/parser/exp-parser.mumble` (record
  construction `{f = e}`, update `e {f = e}`, and selection patterns),
  `src/compiler/parser/pattern-parser.mumble` (record patterns `C {f = p}`).
- **AST:** `src/compiler/ast/type-structs.mumble` — `constr` struct needs
  field-label info.  Add a `field-labels` slot or a new `field-decl` struct.
  `src/compiler/ast/ast.mumble` and `ast-builders.mumble` — new AST nodes
  for record construction/update.
- **Type declarations:** `src/compiler/tdecl/tdecl.mumble` — generate
  selector functions for each field label.  `tdecl-utils.mumble` for
  helpers.
- **Typing:** `src/compiler/type/expression-typechecking.mumble` — type
  check record construction (infer constructor from labels), record
  update (same type, overwrite fields), and field selection.
- **Closure conversion:** `src/compiler/cfn/cfn.mumble` — record update
  desugars to reconstruct with all fields.
- **Derived Show/Read:** `src/compiler/derived/text-binary.mumble` —
  derived `Show` for records uses `C { f1 = ..., f2 = ... }` syntax.
- **Import/export:** `src/compiler/import-export/ie.mumble` — field labels
  are exportable entities.  `C(..)` exports all fields; `C(f1,f2)` exports
  a subset.
- **Scope:** `src/compiler/prec/scope.mumble` — field selectors enter
  scope; record update resolution.

**Approach:**
1. Extend the `constr` struct with field labels (a list of
   `(label-name, field-type)` pairs).  Parse `data C = C { f :: Int, g :: Bool }`.
2. During `tdecl`, generate selector functions: `f :: C -> Int`,
   `g :: C -> Bool`.  These are top-level bindings in the defining module.
3. Record construction `C { f = 1, g = True }` — check all required fields
   are present (for non-partial constructors), desugar to `C 1 True`.
4. Record update `e { f = 2 }` — desugar to `\x -> C 2 (g x)`.  Requires
   knowing the constructor type and all field positions.
5. Record patterns `C { f = n }` — desugar to `C n _` (bind named fields,
   ignore others with wildcards).
6. Derived `Show`: `show (C {f=1})` = `"C {f = 1}"`.

**Example:**
```haskell
data Point = Point { px :: Double, py :: Double }

origin = Point { px = 0, py = 0 }
moved  = origin { px = 5 }
getX p = px p

f (Point { px = x }) = x

showPoint (Point {px = x, py = y}) = "Point {px = " ++ show x ++ ", py = " ++ show y ++ "}"
```

**Tests:**
- `tests/haskell98/language/records-construction.hs` — construct a record,
  select fields, print.
- `tests/haskell98/language/records-update.hs` — update fields.
- `tests/haskell98/language/records-pattern.hs` — pattern match on fields.
- `tests/haskell98/language/records-export.hs` — export/import field labels.
- `tests/haskell98/language/records-derived.hs` — derived Show/Read.
- `tests/haskell98/fail/records-duplicate-field.hs` — duplicate field
  in construction is an error.
- `tests/haskell98/fail/records-missing-field.hs` — missing required field
  in construction is an error.

**Invariants:**
- Field selectors are ordinary functions: `f :: C -> FieldType`.  They
  work on any constructor that has that field.
- Record update preserves the constructor: `e {f = v}` has the same type
  as `e`.
- A type with one constructor can have partial record updates; a type
  with multiple constructors cannot (update is an error if ambiguous).
- Field labels are scoped to the module; importing `C(..)` brings them in.
- Derived `Show` for records must use the brace syntax (H98 Report §10).
- Record syntax must not interfere with existing datatype syntax (no
  labels = plain constructor).

---

### LG-QUALIFIED: Qualified names, `import qualified … as`  *(M7)*

**Status:** ✅ Landed (2026-10-07).  As built, unlike the plan below:
- The lexer (`lex-qualified`) makes `M.x`/`M.C`/`M.+`/`A.B.x` one token
  of the *base* token type with the qualified text, so the parser needs
  no new token categories and `import A.B` reads a dotted module name.
- No two-level table: qualified names are entered in the module's symbol
  table as the symbols `|M.x|` / `|;M.C|` (`qualify-name`,
  `insert-qualified-definition` in `top/symbol-table.mumble`) by
  `import-group` (using the import's `as` name; `qualified` imports skip
  the unqualified entry) and by `create-top-definition` (the module's own
  names).  Implicit-Prelude `Prelude.x` resolves through the base name
  (`resolve-implicit-prelude-qualified`).  Fixity comes from the def, so
  qualified operators keep it.  Nothing new is dumped in interfaces.
- Known deviations from H98: `M..` is not a qualified `.` (so `[Red..]`
  works); a name imported from two modules is an error at import time,
  not only when used (as for unqualified names already); `module M` in an
  export list re-exports M's names even when M was imported only
  qualified; hierarchical module names lex, but `.hu`/file lookup does
  not map `A.B` to a path.

The plan's notes are kept for reference.

**Where:**
- **Lexer:** `src/compiler/parser/lexer.mumble` — `.` always lexes as an
  operator.  Must distinguish `M.name` (qualified) from `a . b` (operator).
  Heuristic: if `.` follows a capitalised identifier (module name), treat
  as qualifier.  Gate on a new feature, e.g. `qualified-names`.
- **Parser:** `src/compiler/parser/module-parser.mumble` (import decls
  with `qualified` and `as`), `src/compiler/parser/exp-parser.mumble`
  (qualified variable/constructor references).
- **Symbol table:** `src/compiler/top/symbol-table.mumble` — currently a
  flat name→def map.  Must support namespaced lookup: `M.name` resolves
  to the entity `name` imported from module `M`.  The `*symbol-table*`,
  `*modules*`, and `*inverted-symbol-table*` globals (in `globals.mumble`)
  are all affected.
- **Scope:** `src/compiler/prec/scope.mumble` — name resolution must try
  qualified lookup when the name contains a `.`.
- **Import/export:** `src/compiler/import-export/ie.mumble`,
  `ie-utils.mumble` — `import qualified M`, `import M as N`, entity
  hiding/selection with qualified names.
- **Interface files:** `src/compiler/backend/interface-codegen.mumble`,
  `dump-interface.mumble`, `import-export/interface-parser.mumble` —
  interface format must carry module qualification.

**Approach:**
1. Add a `qualified-name` AST node (or extend `var-ref`/`con-ref` with an
   optional module qualifier).
2. In the lexer, when encountering `UpperId . VarId` or `UpperId . UpperId`,
  produce a qualified token.  This requires lookahead: the `.` must not be
  followed by whitespace or another operator character (to distinguish from
  function composition).
3. Extend the symbol table to a two-level map: module → name → def.  The
  unqualified lookup falls back to qualified if there's exactly one
  candidate (or errors on ambiguity).
4. `import qualified M` brings names in only as `M.name`.
   `import qualified M as N` aliases the module.
5. `import M (f, C(..))` brings `f` and `C` in unqualified; also available
  as `M.f`, `M.C`.

**Example:**
```haskell
import qualified Data.List as L
import Data.Maybe (fromJust)

main = print (L.sort [3,1,2], fromJust (Just 42))
```

**Tests:**
- `tests/haskell98/modules/qualified-import.hs` — import qualified, use
  `M.name`.
- `tests/haskell98/modules/qualified-as.hs` — `import qualified M as N`.
- `tests/haskell98/modules/qualified-mixed.hs` — qualified and unqualified
  imports of the same module.
- `tests/haskell98/fail/qualified-ambiguous.hs` — ambiguous unqualified
  name from two modules is an error.
- `tests/haskell98/modules/composition-still-works.hs` — `(.)` operator
  still parses as composition, not qualification.

**Invariants:**
- `.` as function composition must still work: `(.) f g x` is composition,
  `Data.List.sort` is qualification.  The distinction is: uppercase-starting
  identifier before `.` = module qualifier.
- The Prelude is always imported unqualified; `Prelude.map` should also
  work if qualified import is enabled.
- Existing 1.2 code that uses `.` as composition must not break (gate
  qualified names on a feature, default off for 1.2).
- Interface files must round-trip qualified names.

---

### LG-IMPTEXP: H98 import/export semantics

**Status:** 🔄 Partial.  C-T rule dropped, partial exports, synonym
exports landed.  Remaining: `renaming` (1.2-only, should be freed),
unhideable PreludeCore, no redefinition of Prelude names.

**Where:**
- C-T rule: `src/compiler/tdecl/instance.mumble` (line ~38–43) — gated on
  dialect; H98 allows instances in any module.
- Export checking: `src/compiler/import-export/ie.mumble`,
  `src/compiler/import-export/ie-utils.mumble`.
- `renaming`: 1.2 import syntax.  Should be a free word in H98 (not a
  keyword).  Check `src/compiler/parser/token.mumble` and `module-parser.mumble`.
- Core symbols: `src/compiler/top/core-symbols.mumble`,
  `prelude-core-syms.mumble` — PreludeCore names are unhideable.

**Remaining work:**
- Free `renaming`, `to`, `hiding`, `interface` as keywords in H98 mode
  (they should be ordinary identifiers).  Verify via `(feature? 'h98-lexing)`.
- Enforce: synonyms must be exported as `T(..)` (not `T` alone); partial
  `T(C1)` with a non-constructor is rejected.
- Ensure no redefinition of Prelude names in H98 mode.

**Example:**
```haskell
-- H98: renaming is a valid variable name
renaming = 42
```

**Tests:**
- `tests/haskell98/syntax/free-keywords.hs` — use `renaming`, `to`,
  `hiding` as variable names.
- `tests/haskell98/fail/redefine-prelude.hs` — redefine `map` → error.
- `tests/haskell98/modules/synonym-export.hs` — export `T(..)` for a
  synonym.

**Invariants:**
- 1.2 mode retains `renaming` as import syntax.
- PreludeCore is always implicitly imported (even with `import Prelude
  hiding (...)`).

---

### LG-DERIVING: Deriving Bounded, H98 Enum, Show/Read for records

**Status:** 🔄 Partial.  Bounded deriving landed
(`derived/ix-enum.mumble`: `bounded-fns`).  H98 Enum deriving landed
(`enum-fns/98`).  Remaining: Show/Read for records (blocked on LG-RECORDS),
nullary-constructor parenthesisation bug.

**Where:**
- All deriving: `src/compiler/derived/derived.mumble` (dispatcher),
  `src/compiler/derived/derived-instances.mumble`.
- Eq/Ord: `src/compiler/derived/eq-ord.mumble`.
- Ix/Enum/Bounded: `src/compiler/derived/ix-enum.mumble`.
- Text/Show/Read: `src/compiler/derived/text-binary.mumble`.

**Remaining work:**
1. **Nullary constructor parenthesisation:** derived `Show` (or `Text`)
   wraps nullary constructors in parens incorrectly.  Find the
   `showsPrec` generation for constructors in `text-binary.mumble` and
   fix the precedence check: nullary constructors should not be
   parenthesised at precedence 0.  (Open bug: `derived-show`.)
2. **Show/Read for records:** once records land, derived `Show` must
   produce `C { f = ..., g = ... }`.
3. **Enum deriving:** `derived/ix-enum.mumble` already generates
   `fromEnum`/`toEnum` for H98.  Verify Enum's Ord superclass is dropped
   in H98 (feature-gated in `enum-fns`).

**Example:**
```haskell
data Color = Red | Green | Blue deriving (Show, Read, Eq, Ord, Enum, Bounded)
-- show Red = "Red" (not "(Red)")
-- [Red ..] = [Red, Green, Blue]
-- minBound = Red, maxBound = Blue
```

**Tests:**
- `tests/haskell98/derived/derive-all.hs` — derive all six classes, test
  each.
- `tests/haskell98/derived/derive-show-nullary.hs` — nullary constructors
  print without parens.
- `tests/haskell98/derived/derive-bounded-product.hs` — Bounded for a
  product type (uses `minBound`/`maxBound` recursively on fields).

**Invariants:**
- Derived instances must match the H98 Report semantics exactly (Report
  §10).
- Deriving must work for both `data` and `newtype`.
- Derived `Eq`/`Ord` compare constructors in declaration order.

---

### LG-POLYREC: Polymorphic recursion via signatures

**Status:** ❌ Missing (M9).  Effort M.

**Where:**
- Dependency analysis: `src/compiler/depend/depend.mumble`,
  `src/compiler/depend/dependency-analysis.mumble` — must respect explicit
  type signatures when building dependency groups.  Currently, a
  polymorphically recursive function without a signature causes an
  infinite type or a monomorphism error.
- Type declaration handling: `src/compiler/type/type-decl.mumble` — must
  use the signature's type variables to generalise, even when the body's
  inferred type is more specific.
- Type checking: `src/compiler/type/expression-typechecking.mumble`.

**Approach:**
1. In `dependency-analysis.mumble`, when a binding has an explicit
   signature, treat it as a strongly-connected component of size 1
   (generalise independently of recursive partners).
2. In `type-decl.mumble`, when checking a binding with a signature,
   instantiate the signature's type variables as fresh generic variables,
   check the body against that type, and generalise — do not infer the
   body's type first.
3. The key insight: polymorphic recursion is undecidable without a
   signature, so requiring a signature is correct (H98 spec).

**Example:**
```haskell
data Nested a = Nest a (Nested [a])

f :: Nested a -> Int
f (Nest _ rest) = 1 + f rest  -- f is called at type Nested [a],
                               -- which is more general than the
                               -- pattern's `a`.  Requires a signature.
```

**Tests:**
- `tests/haskell98/language/poly-rec.hs` — the `Nested` example above.
- `tests/haskell98/fail/poly-rec-no-sig.hs` — polymorphic recursion
  without a signature is an error.

**Invariants:**
- Functions without polymorphic recursion must not change behavior.
- The monomorphism restriction must still apply when there is no signature.
- Explicit signatures must still be checked (the body must be an instance
  of the signature).

---

### LG-MR2: Monomorphism restriction rule 2

**Status:** 🔄 Bug.  Exporting a pattern binding reports "Can't export
pattern binding" instead of allowing it (or giving the correct H98 error).
Open bug 3 (`mr-exported`).

**Where:**
- `src/compiler/type/pattern-binding.mumble` (lines ~26–35) — the MR
  rule 2 check fires on exported pattern bindings.  In H98, exporting a
  restricted (pattern) binding is allowed; rule 2 says the binding is
  not generalised.  The current code errors instead.

**Approach:**
1. In `pattern-binding.mumble`, change the export check: instead of
   erroring, mark the binding as monomorphic (do not generalise its type
   variables) and allow the export.
2. The type should be the monomorphic type (defaulted if possible, else
  the most specific instance).

**Example:**
```haskell
module M (foo) where
(foo, bar) = (1, 2)   -- pattern binding, exported
-- H98: foo :: Num a => a is NOT allowed (MR rule 2)
-- Instead: foo is monomorphic, defaulted to Integer
```

**Tests:**
- `tests/haskell98/prelude/mr-exported.hs` — export a pattern binding,
  use it, verify it's monomorphic.
- `tests/haskell98/fail/mr-generalised.hs` — if a pattern binding would
  need generalisation, it's an error.

**Invariants:**
- Rule 1 (no generalisation of pattern bindings) must still hold.
- Simple (non-pattern) bindings are unaffected.
- 1.2 behaviour must not change (it has its own MR semantics).

---

### LG-DEFAULT: Default `(Integer, Double)`

**Status:** ✅ Landed for H98.  Conditional in `system-init.mumble` (lines
15–23): H98 defaults to `(Integer, Double)`, 1.2 to `(Int, Double)`.

**Remaining issue (open bug 2):** `Int` arithmetic wraps silently, and
in some cases defaulting doesn't fire under an expression signature
(`show (2 ^ 2 :: Int)` → "ambiguous").  See open bugs 1 and 2.

**Where:**
- `src/compiler/top/system-init.mumble` — the default declaration.
- `src/compiler/type/default.mumble` — the defaulting algorithm.
- `src/compiler/type/predicates.mumble` — ambiguity resolution.

**Invariants:**
- Defaulting applies only to MR-restricted variables (not to explicitly
  quantified variables).
- The default list is per-module; `default` declarations override it.

---

### LG-LOCALFIXITY: Fixity declarations in `let`, `where`, class bodies

**Status:** ✅ Landed (§7).  Feature `fixity-anywhere` (H98).

**Where:**
- `src/compiler/prec/prec.mumble` and `prec-parse.mumble` — fixity
  declarations are accepted anywhere a declaration group appears.
- `src/compiler/parser/decl-parser.mumble` — parses fixity decls in
  local scopes.

**Invariants:**
- A local fixity declaration affects only names in its scope.
- Fixity is resolved after parsing (in the `prec` phase), so local
  fixity must be visible during precedence resolution.

---

### LG-HEX: Hex/octal literals

**Status:** ✅ Landed (§7).

**Where:** `src/compiler/parser/lexer.mumble` — numeric literal lexing.
Gated on `(feature? 'h98-lexing)`.

**Invariants:**
- `0x1F` = 31, `0o17` = 15.
- 1.2 mode: `0x1F` lexes as `0` followed by `x1F` (identifier).

---

### LG-TUPLECON: `(,)`, `(,,)`, `(->)`, `[]` as constructors

**Status:** ✅ Landed (§7).

**Where:** `src/compiler/parser/exp-parser.mumble` and `type-parser.mumble`.

**Invariants:**
- `(,)`, `(,,)` etc. are type constructors of kind `* -> * -> ...`.
- `(->)` is `(->) r s` = `r -> s`.
- `[]` is the list type constructor.

---

### LG-PARENLHS: Parenthesised function LHS `(f . g) x = …`

**Status:** ✅ Landed (§7).

**Where:** `src/compiler/parser/decl-parser.mumble` — function definition
LHS accepts parenthesised operator expressions.

**Invariants:**
- `(f . g) x = e` ≡ `f (g x) = e`.
- Must not conflict with qualified-name parsing (LG-QUALIFIED).

---

### LG-LETCOMP: `let` in list comprehensions

**Status:** ✅ Landed (§7).

**Where:** `src/compiler/parser/exp-parser.mumble` — comprehension
qualifiers accept `let`.

**Invariants:**
- `[x | let y = e, ...]` introduces `y` into the comprehension scope.
- `let` qualifiers are desugared to nested `let` in the translation
  (Report §3.11).

---

### LG-STRICT: `!` strictness flags

**Status:** ✅ Landed (§7).  Maps onto the existing STRICT machinery.

**Where:** `src/compiler/parser/decl-parser.mumble` (parses `!` in
constructor fields), `src/compiler/ast/type-structs.mumble` (`constr`
slot `types` carries annotation values), `src/compiler/backend/strictness.mumble`.

**Invariants:**
- `data T = T !Int` makes the `Int` field strict (evaluated before
  construction).
- Equivalent to the old `{-#STRICT#-}` annotation.
- Does not imply strictness in pattern matching (only in construction).

---

### LG-PRAGMAS: H98 pragmas; ignore unknown ones

**Status:** ✅ Landed (§7).

**Where:** `src/compiler/parser/annotation-parser.mumble` — `{-#` pragma
parsing.  Unknown pragmas are ignored rather than erroring.

**Invariants:**
- `{-# OPTIONS -fglasgow-exts #-}` etc. are accepted and ignored (H98
  compilers should ignore unknown pragmas).
- Yale-specific pragmas (`{-#STRICT#-}`, `{-#SPECIALIZE#-}`) still work.

---

### LG-ARROW: `-->` lexes as an operator, not a comment

**Status:** ✅ Landed (§7, H98 only).

**Where:** `src/compiler/parser/lexer.mumble`.  Gated on `(feature? 'h98-lexing)`.

**Invariants:**
- In 1.2, `-->` starts a comment (old Yale behaviour).
- In H98, `-->` is a valid operator.

---

### LG-HEADERLESS: Headerless module means `Main(main)`

**Status:** ✅ Landed (§7, H98 only).

**Where:** `src/compiler/parser/module-parser.mumble`.  Feature
`headerless-main`.

**Invariants:**
- A file without a `module` header is `module Main(main) where`.
- In 1.2, a header is required.

---

### LG-RESERVED: `do` and `newtype` reserved; free `interface`, `renaming`, `to`, `hiding`

**Status:** ✅ Landed (§7/§9).

**Where:** `src/compiler/parser/token.mumble`, `src/compiler/parser/lexer.mumble`.
`do` and `newtype` are reserved words (always, in all dialects ≥ 1.3).
`interface`, `renaming`, `to`, `hiding` are freed in H98 (via `h98-lexing`).

**Invariants:**
- `do` is a layout keyword (starts a layout block).
- `newtype` is a reserved word (cannot be used as an identifier).
- In 1.2, `interface`/`renaming`/`to`/`hiding` are still import syntax.

---

### LG-UNICODE: Unicode `Char`

**Status:** ❌ Missing (M9).  Effort M.  `*max-char*` is 255 (Latin-1).

**Where:**
- Runtime: `src/runtime/runtime.mumble` or `prims.mumble` — find
  `*max-char*` (currently 255).  Change to `char-code-limit` (SBCL) or
  `#x10FFFF`.
- Char primitives: `src/runtime/prims.mumble` — `prim.ord`, `prim.chr`
  must handle full Unicode code points.
- String representation: Haskell `String` is `[Char]`; each `Char` must
  hold a full code point, not a byte.
- Character predicates: `lib/haskell98/Char.hs` — `isAlpha`, `isDigit`,
  etc. must use Unicode-aware predicates.  Currently likely ASCII-only.
- Source files: `src/compiler/parser/lexer.mumble` — must read UTF-8
  source files (SBCL reads UTF-8 with `:external-format :utf-8`).

**Approach:**
1. Change `*max-char*` to support full Unicode.
2. Ensure the image reads source files as UTF-8.
3. Port Unicode-aware character predicates from Hugs or the Report.
4. The Latin-1 fallback is acceptable in practice (Hugs used it until
   2005), so this can be deferred.

**Example:**
```haskell
main = print (ord 'λ', chr 955)  -- λ = U+03BB = 955
```

**Tests:**
- `tests/haskell98/language/unicode-char.hs` — use non-ASCII characters.
- `.xfail` until implemented.

**Invariants:**
- `ord 'A'` = 65 (unchanged).
- `chr 0` = `'\NUL'` (unchanged).
- Latin-1 characters (0–255) must work identically to before.

---

## Prelude and library gaps

### Prelude classes

| Item | Status | Where |
|---|---|---|
| `Ordering`, `compare` | ✅ Landed | `lib/haskell98/prelude/PreludeCore.hs` |
| Enum: drop `Ord` superclass, add `succ`/`pred`/`toEnum`/`fromEnum` | ✅ Landed | `lib/haskell98/prelude/PreludeCore.hs`, `derived/ix-enum.mumble` |
| `Bounded` | ✅ Class landed; deriving ✅ | `PreludeCore.hs`, `derived/ix-enum.mumble` |
| Superclasses: `Num ⇐ Eq, Show`; `Real ⇐ Num, Ord`; `Integral ⇐ Real, Enum`; `Ix ⇐ Ord` | 🔄 Partial — `Num ⇐ Eq, Show` blocked on Show/Read split | `PreludeCore.hs` |
| RealFloat: `isNaN`, `atan2` | ✅ Landed | `PreludeCore.hs` |
| `Functor`, `Monad` | ✅ Landed (blocked on constructor classes, now resolved) | `lib/haskell98/prelude/PreludeIOMonad.hs` |

### Prelude types

| Item | Status | Where |
|---|---|---|
| `Maybe`, `Either`, `Ordering`, `FilePath` | ✅ Landed | `lib/haskell98/prelude/PreludeCore.hs`, `lib/haskell98/Maybe.hs` |
| `IOError` abstract | ✅ Landed | `lib/haskell98/prelude/PreludeIO.hs` |
| Remove `Dialogue`, `Bin`, `Assoc` | 🔄 `Dialogue` compatibility retained; `Bin`/`Assoc` still core types (bug 7) | `src/compiler/top/core-symbols.mumble` |

### Prelude functions

| Item | Status |
|---|---|
| `concatMap`, `replicate`, `lookup`, `curry`, `uncurry`, `undefined`, `seq`, `$!`, `realToFrac`, `maybe`, `either` | ✅ Landed |
| `mapM`, `mapM_`, `sequence`, `sequence_`, `=<<` | ✅ Landed |
| `putChar`, `putStr`, `putStrLn`, `getChar`, `getLine`, `getContents`, `ioError`, `userError`, `catch`, `readIO`, `readLn` | ✅ Landed |
| `take`/`drop`/`splitAt`/`!!` take `Int` | ✅ Landed |
| I/O functions monadic | ✅ Landed |
| Move `Ratio`, `Complex`, `Array`, `zip4`-style, `nub` to libraries | ✅ Landed |

### Libraries

| Module | Status | Notes |
|---|---|---|
| Ratio, Complex | ✅ | Renamed to `Ratio`/`Complex` |
| Ix, Array | ✅ | `rangeSize`, tuple-pair arrays |
| Numeric | ✅ | `showHex`, `showOct`, `showEFloat`, etc. |
| Char | ✅ | `isHexDigit` bug fixed |
| List, Maybe | ✅ | Report code |
| Monad | ✅ | Report code |
| IO | ✅ | Handles, IOError, `catch`, `bracket` |
| System | ✅ | `getArgs`, `exitWith`, `system` |
| Directory | ✅ | All operations via `sb-posix` |
| Time, Locale, CPUTime | ✅ | Report/Hugs code |
| Random | ✅ | Hugs' `System/Random.hs` |

### System library follow-ups (from §7) ✅

All done: `ioeGetFileName`/`ioeGetHandle` and `try` (`IO.hs`),
`BlockBuffering (Maybe Int)` (`IO.hs`, `handle-prims.mumble`), and
`Random` uses `minBound`/`maxBound`/`realToFrac`.

---

## Runtime: class layout and dictionary primitives

### RT-DICTLAYOUT: Generic tuple dictionaries

**Problem:** `src/runtime/tuple-prims.mumble` hard-codes dictionary layouts.
For example, `tupleOrdDict/l` (lines in the file) builds an Ord dictionary
with a fixed number of method slots and checks `(haskell98?)` to decide
whether to include `compare`.  This blocks making `compare` and
`rangeSize` true methods and makes adding a new dialect painful.

**Where:**
- `src/runtime/tuple-prims.mumble` — `tupleOrdDict/l`, `tupleIxDict`,
  `tupleShowDict/l`, `tupleReadDict`, `tupleTextDict/l`, `tupleBoundedDict`.
- `create-dict` macro — builds the dictionary vector from method names
  and superclass dicts.
- `dict-super-slot` — computes superclass position from `class-super*`
  and `class-n-methods` (already somewhat generic).
- `tuple-super-dict-fn` — dispatches on `core-symbol` to find the
  superclass's tuple-dict function (hardcoded list of Eq/Ord/Text/Show).

**Approach:**
1. Make `create-dict` fully data-driven: read method names and
   superclass slots from the class definition (`class-n-methods`,
   `class-super*`) rather than listing them inline.
2. Replace `(haskell98?)` checks with `(feature? ...)` predicates.
3. Make `tuple-super-dict-fn` a table lookup keyed on class name, so a
   new class (e.g. `Read` as a superclass of something) doesn't require
   editing this function.
4. Or: generate per-dialect tuple-dictionary functions at prelude build
   time, eliminating the runtime conditionals entirely.

**Invariants:**
- `dict-super-slot` must compute the correct superclass position from
  the class definition, not a hardcoded offset.
- Adding a method to a class in the Prelude must not break existing
  dictionary layouts (the position is computed from `class-n-methods`).
- 1.2 tuple dictionaries (Text/Binary) must still work.

**Tests:**
- `tests/haskell98/prelude/tuple-eq-ord.hs` — `(==)`, `compare` on
  tuples of various arities.
- `tests/haskell98/prelude/tuple-show.hs` — `show` on tuples.
- Regression: all 1.2 tuple tests.

---

## Open bugs (from §7)

Each has a test in `tests/`, most marked `.xfail`.

### BUG-1: No defaulting under an expression signature

`show (2 ^ 2 :: Int)` is "ambiguous" (`default-in-annotation`).
Also `round 2.5` (only `RealFrac`) is not defaulted (`default-realfrac`).

**Where:** `src/compiler/type/default.mumble`,
`src/compiler/type/predicates.mumble`.  Defaulting doesn't fire when
the ambiguity is under an explicit expression signature.

**Approach:** After type-checking an expression with a signature, if
the residual context contains ambiguous variables that are in the
defaulting classes, apply defaulting to those variables.

**Test:** Remove `.xfail` from `tests/haskell98/.../default-in-annotation.hs`
and `default-realfrac.hs`.

### BUG-2: `Int` wraps silently; default is `(Int, Double)` in some paths

**Where:** `src/compiler/top/system-init.mumble` — verify the H98
default is actually `(Integer, Double)` in all code paths.  The
conditional (lines 18–21) may not cover all cases.
Also: `Int` arithmetic wraps silently (SBCL behaviour).  Consider
overflow detection or documenting it.

**Test:** `default-integer` xfail.

### BUG-3: MR rule 2 — exporting a pattern binding errors

See [LG-MR2](#lg-mr2-monomorphism-restriction-rule-2) above.

### BUG-4: Shallow control stack

Non-tail recursion over 100 000 elements overflows.  The image is built
with `--control-stack-size 512` (Makefile: `STACK_MB ?= 512`).

**Where:** `Makefile` (increase `STACK_MB`), or restructure deeply
recursive runtime primitives.

**Approach:** Increase `STACK_MB` to 1024 or 2048 for the saved image.
Alternatively, identify the non-tail-recursive runtime functions and
make them iterative.

**Test:** `deep-stack` xfail.

### BUG-5: Batch mode diagnostics and extra newline

Compiler diagnostics go to stdout (should be stderr).  After a compile
error, it continues to "The variable #:|mainNNNN| is unbound".
`apply-exec` prints an extra newline after every program
(`command-interface/incremental-compiler.mumble:147`).

**Where:** `src/compiler/command-interface/incremental-compiler.mumble`
(line ~147), `src/compiler/command-interface/command.mumble`,
`src/compiler/top/globals.mumble` (`*haskell-batch-mode*`).

**Approach:**
1. Route diagnostics to `*error-output-port*` in batch mode.
2. After a compile error, exit non-zero instead of continuing.
3. Remove the stray newline in `apply-exec`.

**Test:** Every `.stdout` currently includes the extra newline; remove
it and update all expected outputs.  Add `tests/haskell98/fail/`
tests with `.exit` files for expected non-zero exit.

### BUG-6: Datatype contexts not enforced

`data Eq a => Set a = ...` — the context is parsed but not enforced
(no `Eq` constraint on construction).

**Where:** `src/compiler/tdecl/tdecl.mumble`,
`src/compiler/ast/type-structs.mumble` (`data-decl` has a `context` slot),
`src/compiler/type/expression-typechecking.mumble`.

**Approach:** When constructing a value of a type with a context, add
the context's class constraints to the expression's type.  This requires
threading the data-decl context through to the constructor's type.

**Note:** H98 deprecates datatype contexts; H2010 removes them.  Low
priority, but the parser accepts them so enforcement is better than
silently ignoring.

**Test:** `datatype-context` xfail.

### BUG-7: `Assoc` and `Bin` are compiler core types

H98 programs cannot define `Assoc` or `Bin` because they're wired into
the compiler.

**Where:** `src/compiler/top/core-symbols.mumble`,
`src/compiler/top/core-definitions.mumble` — `Assoc` and `Bin` are in
the core symbol table.

**Approach:** Remove `Assoc` and `Bin` from core symbols for H98 (they
are 1.2-only).  Gate on dialect.  After the Show/Read split (M5), `Bin`
is removed entirely from H98.

**Test:** `prelude-names-free` xfail.

### BUG-8: Case-insensitive filesystem unit-file collision

A `foo.hs` beside a `Foo.hu` picks up the wrong unit file on
case-insensitive filesystems (macOS).

**Where:** `src/compiler/csys/compiler-driver.mumble` — module lookup.

**Approach:** Be case-sensitive in module name matching regardless of
the filesystem, or warn on collisions.

### BUG-9: Flaky prolog test

`tests/haskell-1.2/demo/prolog` failed once under `-j 8`.  Not
reproduced since.  Likely a race in the test runner or a shared-resource
issue.  Monitor; no action unless it recurs.

---

## Cross-cutting invariants (apply to all changes)

1. **Keep the architecture.** Do not rewrite the compiler in Haskell.
   The pipeline order and phase boundaries are sacred.

2. **Gate on features, not dialects.** New dialect-dependent code uses
   `(feature? 'name)`, never raw `(haskell98?)`.  Add new features to
   `*dialect-features*` in `globals.mumble`.

3. **Host-specific code stays in `src/mumble/` and `src/runtime/`.**
   No bare `sb-ext:` / `sb-sys:` calls elsewhere.  Use `#+sbcl`
   conditionals with portable fallbacks.

4. **Generated Lisp keeps readable names.** Haskell module + identifier
   names, not gensyms, so `sb-sprof` output maps back to source.

5. **Every language change needs a test.** Add a `.hs` + `.stdout` (or
   `.exit`) under `tests/<dialect>/`.  Run `make test` before committing.

6. **1.2 must not break.** The 1.2 demos are a fixed regression baseline.
   Changes gated on features should be invisible to 1.2.

7. **Interface files (`.hu`) must round-trip.** Any change to the type
   representation, kind representation, or qualified names must update
   `backend/interface-codegen.mumble`, `backend/dump-interface.mumble`,
   and `import-export/interface-parser.mumble` together.

8. **Don't copy from nhc98.** Its licence is copyleft-ish.  The H98
   Report code and Hugs (BSD) are safe to copy with attribution.

9. **Dictionary layout is computed from class definitions, not hardcoded.**
   `dict-super-slot` and `class-n-methods` drive positions.  Adding a
   Prelude method must not break existing instances.

10. **The `*haskell-dialect*` is set at image-build time** via `$PRELUDE`.
    Each saved image has one dialect.  Do not change dialect at runtime.

---

## Milestone ordering (for planning)

The critical path is M3 → M4 → M5.  M3 and M4 are done.

| Milestone | Status | Blocks |
|---|---|---|
| M0 — Revival | ✅ | — |
| M1 — Modern repo/tooling | 🔄 (CI, regression suite, second host remain) | — |
| M2 — Cheap H98 wins | ✅ | — |
| M3 — Constructor classes | ✅ | M4, M5 (Functor/Monard/Show/Read) |
| M4 — Monadic IO | ✅ | M5 (Prelude I/O rebuild) |
| M5 — Show/Read split | ✅ | — |
| M6 — newtype, then records | ✅ | — |
| M7 — Qualified names, module system | ✅ (deviations in LG-QUALIFIED) | — |
| M8 — System libraries | ✅ | — |
| M9 — Polymorphic recursion, Unicode, conformance | ❌ | — |

**Recommended next milestone:** Complete M5 (Show/Read split).  This
unblocks the `Num ⇐ Eq, Show` superclass fix, removes `Text`/`Binary`/
`Bin`/`Assoc` from H98, and is a prerequisite for record-derived Show/Read.

**After M5:** M6 (records) is the largest remaining language feature.
M7 (qualified names) can proceed in parallel but touches every name
lookup, so it should be its own focused effort.
