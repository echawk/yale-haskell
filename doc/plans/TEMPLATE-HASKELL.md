# Plan: Template Haskell

Status: design only (2026-10-16).  Nothing here is implemented.  This
guide says what Template Haskell (TH) is, how its parts map onto Yale
Haskell's pipeline, which files change, and where the hard parts are,
so that the work can be split into milestones that each end in passing
tests.

Sources:
- T. Sheard and S. Peyton Jones, "Template Meta-programming for
  Haskell", Haskell Workshop 2002: the original design (TH1).
- T. Sheard and S. Peyton Jones, "Notes on Template Haskell Version 2",
  November 2003: the `Name` type, `reify`, error recovery, the `Quasi`
  class (TH2).
- GHC's user guide, section "Template Haskell" (the `TemplateHaskell`
  and `QuasiQuotes` extensions), for today's syntax and rules.
- The `template-haskell` package on Hackage, for the library interface
  programs expect.

## 1. What has to exist

TH has five parts.  A program that uses TH needs all of them, but they
can be built and tested one at a time.

1. **The syntax library.** `Language.Haskell.TH` and its submodules
   define the data types for Haskell syntax: `Exp`, `Pat`, `Dec`,
   `Type`, `Lit`, `Name`, `Clause`, `Body`, `Guard`, `Stmt`, `Con`,
   `Info` and so on.  They also define the `Q` monad, the lower-case
   smart constructors (`varE`, `appE`, `lamE`, `funD`, `dataD`, ...), the
   `Lift` class, the `Quote` class, and a pretty printer (`pprint`).
2. **Splices, run at compile time.** `$(e)` or `$x` in an expression,
   pattern or type position, and a top-level declaration splice
   (`$(e)`, or a bare top-level expression).  The compiler type-checks
   `e`, runs it, and converts the resulting syntax value back into its
   own AST in place of the splice.
3. **Quotes.** `[| e |]` (also `[e| |]`), `[d| decls |]`, `[t| type |]`
   and `[p| pat |]` are desugared into code that builds the syntax
   value, with hygiene:
   - variables bound inside the quote get fresh names;
   - free variables that are global keep their original (module-
     qualified) names;
   - free local variables of the enclosing code are lifted with `lift`.

   Name quotes `'f` and `''T` are values of type `Name`.
4. **Reification.** `reify :: Name -> Q Info` reads the compiler's own
   tables: a type's constructors, a class's methods, a variable's type,
   fixity, and instances.
5. **Quasi-quoters** (`QuasiQuotes`). `[q| any text |]` applies the
   `quoteExp`, `quotePat`, `quoteType` or `quoteDec` field of the
   imported `QuasiQuoter` `q` to the text, as a splice would.

Typed TH (`[|| e ||]`, `$$e`, `Code m a`) is a later milestone.  It
reuses all of the above and adds a typed wrapper.

### Rules that constrain the implementation

- **The stage restriction.** A splice can only run functions defined
  in other modules, which are already compiled and loaded.  It cannot
  run functions from the module being compiled.  GHC's user guide says
  so, although its own `one`/`two` example seems to say otherwise; what
  GHC actually does is reject a splice that uses a same-module function
  ("GHC stage restriction").  Yale gets the same rule for free: imported
  units are compiled and loaded before a dependent unit is compiled
  (`load-compilation-unit` in `src/compiler/csys/compiler-driver.mumble`),
  and the current module's code exists only after all its phases have
  run.
- **Declaration groups.** A top-level declaration splice ends a group.
  Declarations after it see the declarations before it and the splice's
  output; earlier declarations do not see later ones.  `reify` sees up
  to the end of the preceding group.  Expression splices do not split
  groups.
- **Static scope is absolute** (TH2 section 2).  A variable in a quote
  refers to what it refers to where the quote is written, not where the
  result is spliced.  Hence original names (`NameG`) and fresh names
  (`newName`, `NameU`).  `mkName` (`NameS`) is the escape hatch: it is
  dynamically scoped, captured at the splice site.
- **Dollar/bracket cancellation.** `$[| e |] = e`.  This is the test of
  a correct conversion in both directions, and the property tests in
  section 6 check it.
- **Levels.** A variable bound at level n may be used at level n
  (normal use), or at a higher level in a quote: a top-level or
  imported one by its name, a local one through `Lift`.  A splice body
  is one level lower than its context; it may use imported names only.

## 2. Why Yale Haskell is well placed

TH needs the compiler to run Haskell code in the middle of compiling a
module.  GHC does this with a byte-code interpreter or dynamic linking.
Yale already does it routinely: the compiler, the runtime and every
loaded unit live in one Lisp image, and the interactive system compiles
an expression, `eval`s the Lisp, and runs it
(`compile-fragment` in
`src/compiler/command-interface/incremental-compiler.mumble`;
`repl-evaluate` and `repl-run` in
`src/compiler/command-interface/repl.mumble`; `apply-exec` in
`command-utils.mumble`).  A splice is that path, run during compilation
with the module's imports as its environment.  `runIO` is the IO monad
already in the image.

The other half, turning a syntax value back into the compiler's AST,
is ordinary Lisp code walking Haskell data.  The representation is
documented in `src/runtime/runtime-utils.mumble`:
- `make-tagged-data` / `constructor-number` / `tagged-data-select` for
  data;
- `make-tuple` for tuples;
- `haskell-string->string` and `haskell-list->list` for strings and
  lists;
- `force` for fields that are thunks.

## 3. Architecture

### 3.1 The library: `lib/haskell98/Language/Haskell/TH*.hs`

Modules, following the package's layout so that imports work:
- `Language.Haskell.TH`: the public interface, re-exporting the others;
- `Language.Haskell.TH.Syntax`: the data types, `Name`, `Q`, `Quasi`,
  `Lift`;
- `Language.Haskell.TH.Lib`: the smart constructors;
- `Language.Haskell.TH.Ppr`: the pretty printer;
- `Language.Haskell.TH.Quote`: `QuasiQuoter`.

**The data types.**
- **Coverage:** follow the `template-haskell` version that ships with
  the GHC used for comparisons (9.14), so that real code compiles.
  Cover first the constructors the targets use (section 6): literals,
  variables, applications, lambdas, `case`, `let`, `if`, tuples, lists,
  records, `do`, signatures; `FunD`, `ValD`, `DataD`, `NewtypeD`,
  `SigD`, `InstanceD`, `ClassD`, `TySynD`; simple types.
- **The rest of the constructors:** define them all, so that
  pattern-matching code compiles, but let the converter (3.4) report
  "not supported" for the ones Yale cannot express.
- **Licence:** the package is BSD-licensed.  Writing the declarations
  from its documented interface (as Data.Graph and Data.Scientific were
  done) keeps the provenance clear; record the version followed in the
  module header.

**`Name`.**
- Structure: `Name OccName NameFlavour`, with flavours `NameS` (from
  `mkName`), `NameQ` (qualified `mkName`), `NameU` (fresh, from
  `newName`, with a unique `Int`), `NameL`, and `NameG` (global: name
  space, package, module).
- Yale has no packages, so `NameG`'s package is a constant.

**`Q`.**
- Definition: as in TH paper section 8.5, `newtype Q a = Q (IO a)`, or
  over a small environment.  The compiler's services are primitives in
  a new `lib/haskell98/THPrims.hi` (LispName, like `BasePrims.hi`):
  - `qNewName`, `qReport`, `qRecover`;
  - `qReify`, `qReifyInstances`, `qLookupName`;
  - `qLocation`, `qRunIO` (which is just the IO action);
  - `qAddDependentFile`, `qCurrentModule`, `qIsExtEnabled`.
- Outside a splice, the primitives that need the compiler fail, so
  `runQ` works in IO for printing code, as TH2 section 10 describes.
- TH2's `Quasi`-class trick is not needed.  It exists so that GHC's
  type-checker monad can implement `Q`; Yale's primitives reach the
  compiler's state through Lisp special variables bound while a splice
  runs.

**`Lift`.** Instances for the base types, and `DeriveLift` (3.7).

**`Ppr`.** Needed for `pprint`, for error messages, and for an
`--emit splices` stage that shows what each splice produced (GHC's
`-ddump-splices`).

### 3.2 Lexing and parsing

Files: `src/compiler/parser/lexer.mumble`, `exp-parser.mumble`,
`pattern-parser.mumble`, `type-parser.mumble`, `module-parser.mumble`,
`token.mumble`.  All new syntax is gated on
`(language-extension? "TemplateHaskell")` or `"QuasiQuotes"` (see
`lex-language-pragma` in the lexer).  Without the extension, `$`, `[`,
`|` and `'` keep their Haskell 98 meanings.

**Tokens.** `lex-one-token`'s `char-case` needs new tokens.
- `[|`, `[e|`, `[d|`, `[t|`, `[p|`, `|]`, and for typed TH `[||`,
  `||]`.  Today `[` emits its punctuation token with no lookahead, and
  `|` is a varsym.  Pain points:
  - `[x|y<-xs]` is a list comprehension, but with `QuasiQuotes` on,
    `[x|` starts a quasi-quote.  GHC accepts this ambiguity and so
    should Yale, only under the extension.
  - `|]` must not break guards or `(||)` sections: lex `|]` as one
    token only inside a bracket.  Use a bracket-depth counter in the
    lexer, or have the parser split a `||]`.
- `$(`, `$x`, `$$(`, `$$x`: a prefix `$`, with no space after it and
  something other than an operator character or space before it, as
  GHC defines it.  The DataKinds tick code has the helpers to test
  prefix position: `promotion-tick?`, `*char-before-token*`,
  `peek-char-2`.  `$` with spaces around it stays the operator.  A
  qualified `M.$` already has a special case.
- `'f`, `'C`, `''T`: name quotes.  They clash with character literals
  and with the DataKinds promotion tick, both handled at the `#\'`
  branch through `promotion-tick?` and `lex-char`.
  - The rule: `'x'` is a character, and `'x` not followed by `'` is a
    name quote.  GHC also requires `' f'7` (with a space) for a name
    with a quote in it.
  - Under TemplateHaskell the promotion tick and the name quote share
    `'C`.  GHC resolves it by context: a type position means a
    promotion, an expression position a name quote.  The lexer cannot
    see position, so emit one `tick` token and let the type parser and
    the expression parser read it.
- `[quoter|text|]`: the lexer must capture the raw text up to the
  first `|]`, with no tokenizing and no escapes.  It needs a raw-string
  lexing mode like the string-literal one.  The quoter is a (possibly
  qualified) varid; `e`, `d`, `t` and `p` are the quote kinds instead.

**Parser.**
- **Expressions** (`parse-aexp-1`): a splice token gives a `splice`
  node; a bracket token parses the body in the right sub-parser and
  gives a `bracket` node; a name-quote token gives a `name-quote`
  node; a quasi-quote token gives a `quasi-quote` node.  Arrows
  (`at-proc?`/`parse-proc`, wired into `parse-infix-exps`) is the
  model for adding a construct.
- **Patterns** (`parse-apat-1`): `$(e)` gives a pattern splice, and a
  `[q|..|]` a quasi-quote pattern.
- **Types** (`parse-atype`): `$(e)` and `[q|..|]` likewise.
- **Top level** (`parse-module-decls` in `module-parser.mumble`):
  - an explicit `$(e)` at the start of a declaration;
  - a bare expression that is not a declaration (GHC's "naked"
    top-level splice).  Detecting it means trying a declaration parse
    first: an `=` or `::` or `|` after the head makes a declaration,
    otherwise it is a splice.  Do this after the existing `at-*?`
    predicates (standalone deriving, pattern synonyms) have had their
    turn.
- **Declaration groups:** the parser records the order of top-level
  splices and declarations; section 3.3 needs it.

**New AST structs**, in `src/compiler/ast/exp-structs.mumble` (with
patterns and declarations in `valdef-structs.mumble` and types in
`type-structs.mumble`):
- `splice` (kind, expression);
- `bracket` (kind, body);
- `name-quote` (name, type-name?);
- `quasi-quote` (quoter, text, kind);
- `decl-splice`.

Every AST walker has a table entry per struct (`ast-td.mumble`), so
each walker that can meet these nodes before expansion needs a method:
- the scope walker in `src/compiler/prec/`;
- the printers in `src/compiler/printers/`;
- the dependency walker.

After expansion none of them remain, except brackets, which are
desugared away in scope (3.5).

### 3.3 Where splices run: a splice phase

Today `compile-modules` (`src/compiler/top/phases.mumble`) runs each
phase over all modules at once:

    parse
    -> import/export
    -> type declarations (tdecl, with derived instances)
    -> scope (prec)
    -> dependency analysis
    -> type check
    -> cfn -> flic -> optimize -> strictness -> codegen

There is no point in the middle where code can run.  This is the
largest structural change.

**Recommended: a splice phase after import/export.**
1. Parse as now.  Splices and quasi-quotes remain as nodes.
2. Run import/export.  The module's imported environment is now known.
3. New phase, `haskell-expand-splices`, in a new directory
   `src/compiler/th/`.  For each module, in source order:
   1. Take the declarations of the group before the first top-level
      splice.  Run the type-declaration phase on them, in an
      incremental mode, so that `reify` of a type, class or
      constructor defined earlier in the module works.  `deriveJSON
      ''Person`, with `Person` declared above, is the common case.
   2. Run the splice.  Compile its expression as a fragment in an
      environment holding only the module's imports.  Then evaluate,
      run the `Q` action, convert the result (3.4), and insert the
      declarations it produced.
   3. Continue with the next group.

   Expression, pattern and type splices inside declarations are run in
   the same pass, after their group's type declarations.
4. Continue with the remaining phases on the fully expanded module, as
   if the programmer had written the generated code.

**Accepted difference from GHC.** Expansion happens before scope and
type checking, and the expanded module is then checked as one group.
So declarations before a splice can see names the splice defines, and
later groups' instances are visible earlier.  GHC rejects the first and
can resolve instances differently (its user guide shows an INCOHERENT
example).  This is a permissive deviation of the kind GHC-EXTENSIONS.md
already lists, and it avoids making every later phase incremental.
Record it there.

**What the recommendation costs.**
- `reify` of a *variable's type* defined earlier in the same module
  needs that group type-checked before the splice runs.  The
  incremental front end does not provide that.  First answer: support
  `reify` for type constructors, data constructors, classes and
  imported variables, and report "not supported yet" for same-module
  variables.  Most generators (deriving JSON, lenses, Show-like
  instances) reify types, not values.
- Later, to remove the restriction, give each group the treatment the
  REPL already gives definitions:
  - `repl-define` keeps the texts of definitions;
  - `fragment-initialize` and `extend-module` compile a fragment as an
    extension module of its parent;
  - so each declaration group could be compiled as an extension of the
    previous groups, and the groups joined at the end.

  That is the faithful implementation, and the REPL shows the
  mechanism works.  It costs compile time and an assembly step: the
  unit must still write one module interface.

**Running a splice** (new `src/compiler/th/run-splice.mumble`).
- **Environment.** Build a fragment module whose imports are the
  current module's imports, plus `Language.Haskell.TH` (made available
  implicitly, as `implicit-extension-imports` in
  `compiler-driver.mumble` does for other extensions).  Give it one
  binding, `splice%N = <splice expression>`, with the expected type
  forced by a signature (`Q Exp`, `Q [Dec]`, `Q Pat`, `Q Type`).
  - The type check of that signature is the TH typing rule for a
    top-level splice.
  - Same-module names are simply not in scope, which is the stage
    restriction, but the error must say so.  Detect a reference to a
    name the current module defines and report "stage restriction:
    `f` is defined in this module; splices may only use imported
    functions", not "undefined".
- **Compile and run.** Compile it with `compile-fragment` and `eval`
  the Lisp.  Find the binding's value, and run the IO action inside
  the splice context:
  - special variables hold the current module, the splice location,
    the reify environment, the error accumulator for `report` and
    `recover`, and the fresh-name supply;
  - Haskell runtime errors are caught with the existing handlers
    (`with-blackhole-restore`, `haskell-runtime-error`).
- **Cost.** Each splice is a small compilation.  Batching all
  expression splices of a group into one fragment (`splice%1 ...
  splice%N`) saves the per-fragment overhead.  Generators like
  `makeLenses` are called once per type, so per-splice cost matters
  less than the TH library's own compile time.
- **Code the splice calls.** It has to be loaded.  Imported units are
  loaded before the dependent unit is compiled.  Check the
  `cflags-load-code?` paths: modes that only compile (`yale-haskell
  compile`, `--emit`) must still load the imports' code when the
  module has splices.

### 3.4 Converting a syntax value back: TH -> Yale AST

New `src/compiler/th/th-to-ast.mumble`.  It is a Lisp walker over the
run-time representation of `Exp`, `Pat`, `Dec`, `Type` and the rest.

- **Recognising constructors.** Dispatch by name, not by tag.  Look up
  the `con` structs of the TH data types once (by name, in the TH
  library's module), then compare `constructor-number` with their
  `con-tag`.  This survives reordering constructors in the library.
  Every field must be forced (`force`), since fields may be thunks.
- **Names.**
  - `NameS "x"` (from `mkName`) becomes an ordinary unqualified
    `var-ref` or `con-ref`, resolved by the scope phase at the splice
    site: dynamic scoping, as specified.
  - `NameQ` becomes a qualified reference.
  - `NameU` (from `newName`) becomes a fresh identifier no program can
    write (e.g. `x%th17`), consistent within the splice's output.
  - `NameG mod "f"` (from quotes and `'f`) must refer to `mod.f` even
    when `mod` is not imported at the splice site.  This is TH paper
    section 9.1's `T:swap`.  Yale's scope phase looks names up through
    the module's import environment (`lookup-toplevel-name` in
    `prec/scope.mumble`).  It needs a pre-resolved reference: a
    `var-ref` whose definition is already set from the global symbol
    table (`fetch-top-def`, `*modules*` in `top/symbol-table.mumble`),
    which scope leaves alone.  This is one of the pain points (5).
- **Literals.** `IntegerL`, `RationalL`, `CharL`, `StringL` and the
  rest become the existing `integer-const`, `float-const` and other
  constant structs.  Note that TH literals are not overloaded; GHC
  inserts `fromInteger` as it would for source.
- **Declarations.** They become `valdef`, `signdecl`, `data-decl`,
  `class-decl` and `instance-decl` structs, exactly what the parser
  makes.  The expanded module then goes through every later phase
  unchanged.
- **Locations.** Everything converted gets the splice's source
  location, so that errors in generated code point at the splice.
  GHC also prints the generated code; use the `Ppr` printer (3.1) in
  the error.

### 3.5 Quotes: Yale AST -> code that builds TH syntax

New `src/compiler/th/quote.mumble`.  This is the `trE` translation of
TH paper section 9.3, which must know how each variable is bound.

- **When it runs:** in the scope phase (`src/compiler/prec/scope.mumble`
  and `prec-parse.mumble`), after names are resolved and operator
  precedence is applied.  At that point every variable is known to be
  one of three kinds:
  - bound inside the quote: generate `newName "x"` and use the fresh
    name;
  - top-level or imported (global): generate `NameG` with the variable's
    original module, from the `def` struct (`def-module`);
  - local and bound outside the quote: generate `lift x`, which needs
    `Lift t` for its type, a constraint the type checker adds when it
    type-checks the generated code.
- **Untyped quotes need not be type-checked** (GHC no longer checks
  them).  Renaming them is enough, which is why scope is the right
  place.  The generated code is plain Haskell (`appE (varE 'f) (lift
  x)`, ...) and is type-checked as usual.
- **Nested splices inside a quote** (`[| 1 + $(f x) |]`) are copied
  as the expression `f x` of type `Q Exp`, TH paper section 9.3's
  `copy`.
- **Declaration quotes** `[d| ... |]` bind names visible to the rest of
  the quote.  Top-level names in a declaration quote are not renamed
  with `newName` in GHC: they keep their written names (`mkName`
  flavour), so that `[d| f = 1 |]` defines `f`.  Copy that rule.
- **Pattern quotes** `[p| (x, y) |]` give `mkName`-style variables
  (TH2 section 8.3).
- **Precedence.** The quoted AST must keep the fixity resolution that
  prec did, using `InfixE` with explicit parentheses (`ParensE`) or
  already resolved applications.

### 3.6 Reification

New `src/compiler/th/reify.mumble`, behind the `qReify` primitive.
Given a `Name`, find the definition and build an `Info` value.  The
"Haskell data from Lisp" helpers in `runtime-utils.mumble` build the
constructors, again by `con` lookup.

| Asked for | Information | Reply |
|---|---|---|
| Type constructor | `algdata` (`ast/definitions.mumble`): tyvars, constructors with their field types and strictness, field labels (`con-field-labels`), newtype flag | `TyConI (DataD ...)` |
| Type synonym | `synonym` struct | `TyConI (TySynD ...)` |
| Class | `class` struct: superclasses, methods with their signatures | `ClassI` with its instances (`instance` structs) |
| Data constructor | the `con` | `DataConI` with its signature, `con-signature` |
| Variable | `var-type` or `var-signature` | `VarI` |
| Fixity | `def-fixity` | `reifyFixity` |

**Supporting work.**
- **Type conversion:** `ntype`/`gtype` (`ast/tc-structs.mumble`) to TH
  `Type` needs a converter that mirrors the type printer
  (`printers/print-ntypes.mumble`): `ntycon`, `ntyapp`, `gtyvar` and
  contexts.
- **Imported modules:** a type from an imported unit is available from
  its interface.  Check that the dumped interface keeps what `reify`
  needs (`csys/dump-interface.mumble`): constructor field types and
  strictness are dumped, while deriving clauses are not, and GHC
  returns an empty deriving list too (TH2 section 5).
- **Instances:** `reifyInstances` asks the instance tables
  (`util/instance-manager.mumble`, `lookup-instance`).

### 3.7 `Lift` and `DeriveLift`

- **Instances:** `Lift` instances for Int, Integer, Char, Bool,
  Double, lists, tuples, Maybe, Either and `()` go in the library.
- **`DeriveLift`:** a new deriving class in
  `src/compiler/derived/`, generated the way `Show` is
  (`derived-instances.mumble`, `ast-builders.mumble`).
  - For each constructor it generates `lift (C a b) = conE 'C \`appE\`
    lift a \`appE\` lift b`, with the constructor as a `NameG`.
  - `liftTyped` comes with typed TH.

### 3.8 Units, the cache, and side effects

- **Imported code must be loaded.** A module with splices needs its
  imports' code loaded, even in modes that only compile.
- **Cache staleness.** A splice's result can depend on more than the
  sources:
  - files read with `runIO` or `addDependentFile`;
  - environment variables;
  - the imported modules' code, which the cache already tracks.

  `qAddDependentFile` should add to the unit's source dependencies
  (`unit-source-dependencies` in `compiler-driver.mumble`, where CPP's
  included files already go), so that the unit cache recompiles when
  such a file changes.  `runIO` effects otherwise are the programmer's
  responsibility, as in GHC.
- **The lock.** Splices run during compilation, possibly in
  concurrent compiles of the same unit.  The unit-cache lock of
  2026-10-16 covers writing; a splice's own side effects are not
  protected.
- **The REPL.** Splices in expressions and declarations typed at the
  prompt go through the same phase.  `compile-fragment` already builds
  a module.

### 3.9 Errors and recovery

- **The `Q` interface:** `report`/`reportError`/`reportWarning`, and
  `recover` (TH2 section 6).  `fail` in `Q` is an error at the splice.
  Implement recovery with a Lisp `handler-case` around the action.
  `report` accumulates messages, and an error report causes `recover`'s
  handler to run.
- **Where errors point:** errors in generated code show the splice's
  location and the generated declarations, printed with `Ppr`.
- **`--emit splices`** (`src/compiler/command-interface/batch.mumble`,
  `*emit-stages*`): prints each splice and its expansion.  This is the
  main debugging aid for TH users and for this implementation.

## 4. Milestones

Each milestone ends with tests in `tests/haskell98/th/`, in the usual
layout: `.hs`, `.stdout`, and `.flags` with `-XTemplateHaskell` or the
pragma.  Each gets a row in GHC-EXTENSIONS.md and a commit.

1. **Library, no compiler support.**
   - `Language.Haskell.TH` data types, `Q` over IO, `newName`,
     `mkName`, `Lift` base instances, `Ppr`.
   - Test: build syntax with the smart constructors, then `runQ` and
     `pprint` the result.  The output can be compared with GHC's.
2. **Expression splices from imported functions.**
   - Lexer and parser: `$(...)` and `$x` in expressions.
   - The splice phase, with the fragment runner and the converter for
     `Exp`, `Lit` and `Pat`.
   - Test: the `extensions.py` TemplateHaskell probe
     (`$(litE (integerL (product [1 .. 10])))`) passes.  Splices in
     a module using a helper module's generators also pass.
3. **Quotes.** `[| |]`, `[p| |]`, `[t| |]` and name quotes, with the
   three kinds of variable.
   - Test: dollar/bracket cancellation, `$[| e |] = e`, as property
     tests over a set of expressions.
   - Test: the TH paper's `printf`, `sel`, and `zipN`, and TH2's
     scoping example (the `x` in `g y = [| x + y |]` stays the
     top-level `x`).
4. **Declaration splices and `[d| |]`.**
   - Top-level splices, explicit and bare.  Converter for `Dec`.
   - `reify` for types, constructors and classes.
   - Test: a hand-written `deriveShow ''T` generator, a `makeLenses`-
     like generator, and the paper's `genZips 20`.
5. **QuasiQuotes.**
   - Raw-text lexing, `QuasiQuoter`.
   - Test: a small expression quasi-quoter, e.g. a string-interpolation
     quoter, in expression and pattern position.
6. **`reify` of same-module values**, through per-group compilation (3.3).
7. **Typed TH**: `[|| ||]`, `$$`, `Code`, `liftTyped`.

**Real targets after milestone 4:**
- QuickCheck's `$(quickCheckAll)`.  optparse's test suite currently
  replaces it by hand (`tools/conformance/optparse.py`).  Dropping that
  adaptation is a direct test.
- A small aeson-style `deriveJSON`.
- `makeLenses` from a lens-style library.

## 5. Pain points, in order of difficulty

1. **No point in the pipeline to run code mid-module.**
   `compile-modules` is batch, phase by phase, over whole modules.  The
   splice phase after import/export, with incremental type declarations
   for `reify`, is the smallest change that works.  Full declaration-
   group semantics, where each group is type-checked before the next
   splice, is the expensive part.  Leave it until a program needs it.
2. **Original names across modules (`NameG`).** Generated code must be
   able to reference `Mod.f` when `Mod` is not imported at the splice
   site.  Scope resolution is import-based, so it needs pre-resolved
   references that scope accepts as they are, and interface loading
   that can find `Mod` (the unit is loaded if the generator's module
   imported it, which it did).
3. **Lexing.**
   - `$` becomes whitespace-sensitive.
   - `[x|` is ambiguous with comprehensions under `QuasiQuotes`.
   - `'` serves character literals, DataKinds ticks and name quotes.
   - Quasi-quote bodies need a raw-text lexing mode.
   - `|]` interacts with guards and `||`.

   Each is local, but the lexer is shared by every program, so every
   change must be gated on the extension, with regression tests that
   the Haskell 98 meaning is unchanged without it.
4. **Hygiene in quotes.** Classifying every variable (bound inside,
   global, local-outside) needs scope information.  Declaration quotes
   have their own non-renaming rule, and binding positions in nested
   splices are subtle (TH2 section 8).  Do quotes in scope, after
   renaming, and copy GHC's rules rather than the 2003 notes'
   proposals (`%x` dynamic syntax was never adopted; `mkName` is the
   mechanism).
5. **The size of the TH data types.** `Dec`, `Type` and `Exp` have
   dozens of constructors in current `template-haskell`.  Generated
   code from real libraries uses many of them (`SigD`, `PragmaD`,
   `StandaloneDerivD`, `KindedTV` binders, `ForallT`, `AppT` with
   promoted types).  The converter must at least recognise all of them
   and report what Yale cannot express, instead of crashing.
6. **Reify fidelity.** Yale's `ntype` has no kinds, no explicit
   `forall` for most types, and `newtype` erased after cfn.  Reify must
   run before cfn, which the splice phase does.  Kinds of type
   variables have to be reported as `*` or guessed.
7. **Cost.** Every splice compiles a fragment and the TH library is
   large.  Mitigations:
   - the TH library is a cached unit, compiled once;
   - batch splices per group;
   - keep fragments small.
8. **Error quality.** Errors in generated code are confusing (TH paper
   section 12 says the same).  The plan for this is `--emit splices`,
   locations on generated nodes, and printing the generated code in
   errors.

## 6. File checklist

| Area | Files |
|---|---|
| Library | new `lib/haskell98/Language/Haskell/TH.hs`, `.../TH/Syntax.hs`, `.../TH/Lib.hs`, `.../TH/Ppr.hs`, `.../TH/Quote.hs` (+ `.hu` files); new `lib/haskell98/THPrims.hi` |
| Primitives | new `src/base/th-runtime.lisp` (Q services: name supply, report/recover, location, dependent files), registered in `yale-haskell.asd` and `tools/build/runtime.lisp` like `text-runtime.lisp` |
| Lexer | `src/compiler/parser/lexer.mumble` (`lex-one-token`, the `#\'` and `#\[` branches, prefix-`$`, raw quasi-quote text), `token.mumble` |
| Parser | `exp-parser.mumble` (`parse-aexp-1`, `parse-infix-exps`), `pattern-parser.mumble` (`parse-apat-1`), `type-parser.mumble` (`parse-atype`), `module-parser.mumble` (`parse-module-decls`, top-level splices) |
| AST | `src/compiler/ast/exp-structs.mumble`, `valdef-structs.mumble`, `type-structs.mumble` (new node structs), `ast-td.mumble` (walker tables) |
| Phases | `src/compiler/top/phases.mumble` (`compile-modules`: the new splice phase after `haskell-import-export`); `tdecl/` (incremental type declarations for reify) |
| TH proper | new directory `src/compiler/th/`: `run-splice.mumble`, `th-to-ast.mumble`, `quote.mumble`, `reify.mumble`, and a unit file like `derived/derived.mumble`, added to the compiler's unit list |
| Scope | `src/compiler/prec/scope.mumble` (quotes translated here; pre-resolved `NameG` references accepted; stage-restriction message) |
| Deriving | new `src/compiler/derived/lift.mumble`, hooked into `derived-instances.mumble` |
| Driver | `src/compiler/csys/compiler-driver.mumble` (`implicit-extension-imports` for the TH library; load imports' code when a module has splices; `unit-source-dependencies` gains dependent files) |
| REPL / CLI | `incremental-compiler.mumble` (fragment runner shared with splices), `batch.mumble` (`--emit splices`) |
| Printers | `src/compiler/printers/` (print the new nodes) |
| Tests | new `tests/haskell98/th/`; `tools/conformance/extensions.py` (TemplateHaskell probe); `tools/conformance/optparse.py` (drop the `quickCheckAll` adaptation) |
| Docs | this file; GHC-EXTENSIONS.md (move TH from "not realistic" to supported, with the declaration-group deviation); FUTURE-TARGETS.md section 2 |
