# GHC extensions: what Yale Haskell supports, and what is realistic

Status: assessment and record (2026-10-11; 2026-10-12: cubicaltt, a
3,000-line GHC program, runs unchanged — CUBICALTT.md).  Measured by
`tools/conformance/extensions.py` (one small program per extension or
library idiom, compared with GHC 9.14's output and exit code) and by the
nofib suites (`tools/conformance/nofib.py`, with `--suite real
--suite shootout --suite gc --try-all` for the larger programs).

## Summary

| measure | before this round | now |
|---|---|---|
| extension and library probes | 28 of 28 (only what was implemented) | 101 of 104 (2026-10-15; 83 of 87 before the last 17 probes) (59 probes added for GHC2021, the common non-2021 extensions, modern libraries, and what cubicaltt, LambdaPi, Mini-TT and husk-scheme needed) |
| nofib imaginary + spectral | 68 pass | 69 pass (mandel) |
| nofib real + gc + shootout | 28 pass, 11 compile errors, 2 wrong, 1 timeout | 40 pass, 2 known (ByteString pointers), no failures |

The two failing probes: GHCIntWraps (a deliberate departure: Int is
the 63-bit fixnum) and QuantifiedConstraints.  Typeable is
GHC's: every type constructor is Typeable without an instance (the type
checker builds the dictionary from the constructor's name and the
arguments' dictionaries, util/instance-manager.mumble), so typeOf, cast
and Data.Dynamic work and show types as GHC does.

Every GHC2021 extension is accepted except where a probe below says
otherwise, and so are most of the extensions modern code turns on beyond
GHC2021.  What is left is either large (Template Haskell, the runtime's
concurrency) or rare (QuantifiedConstraints).

## How extensions are switched on

The lexer records each file's `{-# LANGUAGE ... #-}` pragmas
(`language-extension?` in the parser, `module-extension?` afterwards,
the module's `extensions` slot).  Extensions that change the meaning of
existing syntax (OverloadedStrings, OverloadedLists, NegativeLiterals,
MonadComprehensions, BlockArguments, PostfixOperators, RecursiveDo,
OverloadedRecordDot, MagicHash, TypeOperators, DataKinds,
DeriveAnyClass) act only when named.  Pure additions (new syntax that
was an error before) are accepted always.  Extensions that add implicit
imports (OverloadedStrings: Data.String; OverloadedLists: GHC.IsList;
RecursiveDo: Control.Monad.Fix) add them for the dependency scan too.

A language standard (GHC2021, GHC2024, Haskell2010, Haskell98) in a
pragma, in a package's default-language, or as `--ghc2021` /
`--ghc2024` on the command line stands for its extensions (lexer
.mumble's `language-standard-extensions`, after GHC's users guide);
`-X NAME` adds one for every module, and `NoNAME` removes one.

## Where GHC departs from the Report

GHC's users guide lists where GHC itself differs from Haskell 98 and
2010 ("Haskell standards vs. Glasgow Haskell", bugs.html).  Programs
written for GHC rely on these, so `--modern-prelude` follows GHC where
it can; `--haskell98` follows the Report except where noted.  The probes
named `GHC...` in tools/conformance/extensions.py check them against
GHC 9.14.

| GHC behaviour | here |
|---|---|
| derived Show of a record argument in parentheses, `Just (R {f = 1})` | as GHC (probe GHCShowRecordParens) |
| `read` of Int/Integer accepts `0x`, `0o`, `0b` | as GHC in both modes (GHCReadHexInt); the Report's would fail, so only a failure becomes a value |
| `splitAt` strict in its count | as GHC (GHCSplitAtStrict) |
| instances `Functor ((->) r)`, `Monad ((->) r)`, `Functor ((,) a)`, `Functor`/`Monad (Either e)` | as GHC (GHCExtraInstances) |
| `array` with a repeated index: the last value | as GHC (GHCArrayLastWins) |
| `maxBound :: Char` is `'\1114111'` | as GHC (GHCCharMaxBound) |
| `Word` exported by the Prelude | with `--modern-prelude` (GHCPreludeWord) |
| `Monad` has an `Applicative` superclass; `fail` is MonadFail's | with `--modern-prelude` |
| `Num` has no `Eq`/`Show` superclasses | with `--modern-prelude` (2026-10-14): the class, shared with `--haskell98`, keeps them, but an `instance Num F` without `Eq F` or `Show F` gets stub instances whose methods are errors (tdecl/instance.mumble's add-num-superclass-stubs), so GHC's programs compile; using `==` or `show` on F is then a run-time error where GHC gives a type error (GHCNumNoSuperclasses) |
| `Int` is 64 bits and wraps modulo 2^64 | **no**: Int is SBCL's fixnum, -2^62 .. 2^62-1, and arithmetic wraps modulo 2^63; `fromIntegral` of an Integer outside that range wraps likewise (GHCIntWraps; nofib sphere).  A 64-bit Int would put a fixnum-or-bignum check on every Int load from the heap |
| `Bits` has no `Num` superclass | **no**: the Report's `Num` superclass is kept (Haskell 2010 code uses it); GHC's additions (FiniteBits, zeroBits, bitSizeMaybe, `.<<.`, bitDefault, ...) are there (DataBitsModern) |
| NondecreasingIndentation (GHC: in its Haskell98 language only) | accepted in both modes |
| an operator in a do block's column closes the block (parse-error(t)) | yes |
| a record's `}` and other explicit braces open an explicit layout context | yes |
| dependency analysis ignores references to variables with signatures | yes |

GHC2021, GHC's default language, is probed extension by extension; of
GHC2024's additions, DataKinds, DerivingStrategies, GADTs, LambdaCase,
RoleAnnotations (accepted, not checked), DisambiguateRecordFields,
ExplicitNamespaces (`type` in import and export lists) and
MonoLocalBinds are probed too.

## The tiers

### 1. Supported as GHC does it

Syntax: LambdaCase, TupleSections, MultiWayIf, BangPatterns,
BinaryLiterals, NumericUnderscores, HexFloatLiterals, NumDecimals,
NegativeLiterals/LexicalNegation, ImportQualifiedPost, PackageImports
(package ignored), BlockArguments, EmptyCase, EmptyDataDecls,
EmptyDataDeriving, PostfixOperators, ParallelListComp,
MonadComprehensions, ViewPatterns, RecursiveDo (one rec group for an
`mdo`), PatternSynonyms (across modules since 2026-10-12: the resolved
pattern travels in the interface; since 2026-10-14 `pattern P` in
export and import lists, `pattern P :: t` typing the builder,
multi-clause explicit builders, and view patterns inside a synonym,
which become top-level functions `view%P%k` and, at a use, pattern
guards (not in lambdas or pattern bindings)), OverloadedStrings,
OverloadedLists, OverloadedRecordDot, DuplicateRecordFields (fields
found through the constructor; `e.f` through a generated
`HasField%f r a | r -> a` class),
NamedFieldPuns, RecordWildCards, StandaloneDeriving (same module),
InstanceSigs, KindSignatures, StandaloneKindSignatures,
PartialTypeSignatures and NamedWildCards (a signature with a wildcard is
dropped and the type inferred), TypeApplications, TypeOperators,
DerivingStrategies, DerivingVia, DeriveAnyClass, DefaultSignatures,
DeriveFunctor/Foldable/Traversable, GeneralizedNewtypeDeriving,
FlexibleInstances, FlexibleContexts, TypeSynonymInstances,
MultiParamTypeClasses, FunctionalDependencies, UndecidableInstances (in
the mtl style), ConstrainedClassMethods, ConstraintKinds (constraint
synonyms), ScopedTypeVariables, PolyKinds (kinds are not checked at
all), CPP (with Cabal's MIN_VERSION_pkg(a,b,c) answered from the
package versions Yale's libraries follow, `cpp-min-version`), overlapping
instances (OVERLAPPABLE/OVERLAPPING: the most specific matching flexible
head is used; the pragmas are not needed), and a catch-all instance
`instance ctx => C a` (2026-10-14: one per class, used at any type no
other instance of C is for, and at a type variable whose context
implies ctx; util/instance-manager.mumble's catch-all-instance),
Arrows (2026-10-15: `proc` with `-<`, `-<<`, `do` binds, `let` and
`if`, translated in the parser into Control.Arrow's combinators,
parser/exp-parser.mumble; not `rec`, `case` commands or banana
brackets).

Haskell 98 and 2010 points fixed on the way (2026-10-12): a Prelude class
method hidden by `import Prelude hiding ((*))` can be defined again; an
instance may bind the methods of a class imported only qualified; the
monomorphism restriction keeps every type variable of a restricted
group's pending constraints monomorphic (`Eq (t b)` on Foldable's `t`, a
variable only a functional dependency determines), instead of
generalizing and then failing to default it; a signature's
multi-parameter constraints improve the body's by functional dependency
(`(Show t, Stream s m t) => s -> m String`).

### 2. Supported permissively: what GHC accepts runs; less is rejected

These follow one rule: Yale Haskell's Hindley-Milner checker is not
extended to GHC's full constraint solver, so the extension is typed
just enough to resolve overloading and run correctly, and a program
GHC accepts behaves the same.  An ill-typed program GHC would reject may
be accepted.

- **RankNTypes**: polytypes as arguments and fields, with contexts; an
  argument without a context is not checked to be polymorphic.
- **ExistentialQuantification**: no escape check.
- **GADTs**: constructors are typed exactly; a match does not refine
  types locally, its right-hand side is coerced instead
  (`type/existentials.mumble`).  A right-hand side whose type is
  ambiguous without the refinement is defaulted.
- **TypeFamilies**: open, closed and associated type families, data
  families.  Reduction happens during unification; an application not
  yet decided is deferred and retried, and dropped if never decided
  (`util/type-utils.mumble`, `type/unify.mumble`).  No overlap or
  termination checks; data families are injective, type families are
  not assumed to be.
- **DataKinds**: promoted constructors are empty types; kinds are not
  checked.  With GADTs and TypeFamilies, length-indexed vectors and
  type-level arithmetic work; so do type-level lists (`'[]`, `'[a, b]`,
  `t ': ts`, built from PromotedNil and PromotedCons) and the HList
  idiom: a class over a promoted Nat and a list, selected by type
  applications (tests/haskell98/language/hlist.hs).
- **AllowAmbiguousTypes**: a class method need not mention the class's
  variables; type applications choose the instance.
- **coerce** (Data.Coerce) has type `a -> b`: no Coercible check.
- **IsString [a]** is an instance for every element type (base's
  `a ~ Char`).

### 3. Supported by approximation (the program runs, the cost differs)

- **MagicHash, UnboxedTuples**: no unboxed types.  `I#` is the identity,
  `Int#` is `Int`, primops are the ordinary operations (GHC.Exts,
  GHC.Base, GHC.Prim), `(# a, b #)` is a tuple.  nofib's spectral-norm
  and compress2 use this.
- **Data.Text, Data.ByteString**: packed (2026-10-14): a Text is a
  Lisp string, a ByteString a Lisp string of characters 0..255
  (lib/haskell98/TextPrims.hi, src/base/text-runtime.lisp), the common
  operations primitives, files read in one piece.  The lazy variants
  are the strict types.  Pointer-level access (Data.ByteString.Unsafe,
  .Internal's ForeignPtr) is not provided.
- **Control.Concurrent, STM**: one thread.  `forkIO` runs the thread to
  completion; an MVar or STM operation that would block fails.  Worker
  threads that report through MVars work (nofib fannkuch-redux,
  binary-trees).
- **Control.Parallel, Control.Parallel.Strategies** (the parallel
  package): real parallelism.  With `+RTS -N[n]` (or `GHCRTS`), `par`
  sparks are evaluated by a pool of lparallel worker threads, and thunk
  evaluation becomes thread-safe from the first spark (a compare-and-swap
  claim; another thread waits on a claimed thunk; a failed spark's
  thunks go back to unevaluated, so the error is raised where the value
  is demanded); see src/base/parallel-runtime.lisp.  Without -N, `par`
  does nothing, as with GHC's non-threaded runtime.  SBCL only.  Not
  there: `forkIO` threads in parallel (they still run one at a time),
  Control.Monad.Par, ParallelArrays, spark statistics (`+RTS -s`), and a
  `<<loop>>` report for a thunk that is re-entered after parallel
  evaluation has started (it waits instead).  Reading an evaluated thunk
  inline has no read barrier (sequential code would pay for it); on arm64
  that leaves a theoretical window in which a thread sees another's
  just-finished thunk's claim instead of its value (not observed).
- **GHC.Generics, Control.DeepSeq**: the classes exist and deriving
  them gives empty instances, so programs that derive them for a library
  compile.  Generic representations and deep `rnf` for user types (it
  evaluates to WHNF) are not there.  Data.Typeable is complete for types
  of kind `*` and their constructors (`typeOf`, `cast`, Data.Dynamic);
  `Typeable (f a)` for a type variable `f` is not.

### 4. Not supported yet, but realistic

| extension | what it needs | size |
|---|---|---|
| QuantifiedConstraints | contexts with `forall` in instance heads; dictionary functions as dictionary fields | medium-large |
| Real concurrency | `forkIO` threads on SBCL threads: blocking MVars and STM, and the IO primitives' shared state (thunk update is thread-safe already, Control.Parallel) | large |
| GHC.Generics' `Rep` | type families exist now; the derived `from`/`to` and the representation types | large |

### 5. Not realistic here

- **TemplateHaskell / QuasiQuotes**: in progress (TEMPLATE-HASKELL.md):
  the library, name quotes ('f, ''T), quotes ([| |], [p| |], [t| |],
  [d| |]), expression and declaration splices of imported functions, and
  reify of types and constructors work; QuasiQuotes and typed TH do not
  yet.
- **GHC's runtime features**: `+RTS` options, profiling, the GHC event
  log, `GHC.Stats`, sparks (`par` is ignored), weak pointers with
  finalizers' timing, stable names.
- **The package ecosystem as Cabal sees it**: Yale Haskell compiles
  source modules; libraries are added as modules under `lib/haskell98`.

## What running "modern Haskell" needs now

The probes say the language is mostly there.  The gaps that real
programs hit first are, in order:

1. **Libraries.**  Each modern program imports a few packages beyond
   base.  text, bytestring, containers, mtl, transformers, stm,
   deepseq, parsec (3.1.18, the unchanged source as a `:package` unit:
   compiled against base's Prelude in every mode), filepath, time
   (Data.Time.Clock), QuickCheck (a subset) and haskeline (without line
   editing) exist now (some as approximations); vector,
   unordered-containers, aeson, optparse-applicative and process do
   not.  These are mostly Haskell and could be ported
   module by module (GHC-specific internals are the obstacle: vector's
   primitive arrays map onto Yale's MutArr).
2. **Record update of a duplicated field** (`r { name = x }` with
   `name` in several types) needs the record's type; construction,
   patterns and `r.name` work.
3. ~~Performance of the String-backed Text and ByteString~~: packed
   since 2026-10-14 (bench/RESULTS.md: textproc 4.5 s -> 0.46 s).
4. **Concurrency** for servers and parallel programs.

## Implementation map

| extension | where |
|---|---|
| pragma recording | parser/lexer.mumble (`lex-language-pragma`), parser-driver.mumble, top/globals.mumble (`module-extension?`) |
| syntax extensions | parser/lexer.mumble, exp-parser.mumble, pattern-parser.mumble, decl-parser.mumble, type-parser.mumble, module-parser.mumble |
| DerivingVia, anyclass, newtype strategy | derived/derived-instances.mumble (`add-special-derived-instance`) |
| DefaultSignatures | tdecl/class.mumble (`init-methods`) |
| GADTs | parser/typedecl-parser.mumble (`make-gadt-constr`), tdecl/alg-syn.mumble, type/existentials.mumble |
| TypeFamilies | parser/typedecl-parser.mumble, tdecl/alg-syn.mumble (`process-family-equations`), util/type-utils.mumble (reduction), type/unify.mumble (deferral, injectivity) |
| ConstraintKinds | tdecl/alg-syn.mumble (`constraint-synonym-body`), util/signature.mumble (`expand-constraint-synonyms`) |
| DataKinds | parser/lexer.mumble (`promotion-tick?`), module-parser.mumble (`add-promoted-constructors`) |
| PatternSynonyms | parser/pattern-parser.mumble (templates for other modules), prec/prec-parse.mumble, prec/scope.mumble, csys/dump-interface.mumble |
| overlapping instances | util/instance-manager.mumble (`lookup-instance/type`), tdecl/instance.mumble, type/unify.mumble (`unify-with-only-instance-head`) |
| DuplicateRecordFields, OverloadedRecordDot | parser/module-parser.mumble (`add-duplicate-record-fields`), lexer.mumble (`record-dot-here?`), exp-parser.mumble, prec/scope.mumble |
| binary handles, catch laziness | runtime/handle-prims.mumble (`prim.h-set-binary-mode`), runtime/io-errors.mumble and base/base-runtime.lisp (catch no longer forces the action's result) |
| libraries | lib/haskell98/{Data,Control,GHC,System,Unsafe}/ |
