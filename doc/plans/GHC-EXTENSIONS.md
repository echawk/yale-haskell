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
| extension and library probes | 28 of 28 (only what was implemented) | 73 of 78 (50 probes added for GHC2021, the common non-2021 extensions, modern libraries, and what cubicaltt needed) |
| nofib imaginary + spectral | 68 pass | 69 pass (mandel) |
| nofib real + gc + shootout | 28 pass, 11 compile errors, 2 wrong, 1 timeout | 40 pass, 2 known (ByteString pointers), no failures |

The five failing probes: DeriveDataTypeable (typeOf), QuantifiedConstraints,
a catch-all instance (`instance Show a => Pretty a`), Arrows,
TemplateHaskell.

Every GHC2021 extension is accepted except where a probe below says
otherwise, and so are most of the extensions modern code turns on beyond
GHC2021.  What is left is either large (Template Haskell, the runtime's
concurrency) or rare (Arrows, QuantifiedConstraints).

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

## The tiers

### 1. Supported as GHC does it

Syntax: LambdaCase, TupleSections, MultiWayIf, BangPatterns,
BinaryLiterals, NumericUnderscores, HexFloatLiterals, NumDecimals,
NegativeLiterals/LexicalNegation, ImportQualifiedPost, PackageImports
(package ignored), BlockArguments, EmptyCase, EmptyDataDecls,
EmptyDataDeriving, PostfixOperators, ParallelListComp,
MonadComprehensions, ViewPatterns, RecursiveDo (one rec group for an
`mdo`), PatternSynonyms (across modules since 2026-10-12: the resolved
pattern travels in the interface), OverloadedStrings,
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
all), CPP, overlapping instances (OVERLAPPABLE/OVERLAPPING: the most
specific matching flexible head is used; the pragmas are not needed).

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
  type-level arithmetic work.
- **coerce** (Data.Coerce) has type `a -> b`: no Coercible check.
- **IsString [a]** is an instance for every element type (base's
  `a ~ Char`).

### 3. Supported by approximation (the program runs, the cost differs)

- **MagicHash, UnboxedTuples**: no unboxed types.  `I#` is the identity,
  `Int#` is `Int`, primops are the ordinary operations (GHC.Exts,
  GHC.Base, GHC.Prim), `(# a, b #)` is a tuple.  nofib's spectral-norm
  and compress2 use this.
- **Data.Text, Data.ByteString**: the APIs over `String`.  Semantics
  match; the packed representation's speed does not.  Pointer-level
  access (Data.ByteString.Unsafe, .Internal) is not provided.
- **Control.Concurrent, STM**: one thread.  `forkIO` runs the thread to
  completion; an MVar or STM operation that would block fails.  Worker
  threads that report through MVars work (nofib fannkuch-redux,
  binary-trees).
- **GHC.Generics, Data.Typeable, Control.DeepSeq**: the classes exist
  and deriving them gives empty instances, so programs that derive them
  for a library compile.  Generic representations, `typeOf`, and deep
  `rnf` for user types (it evaluates to WHNF) are not there.

### 4. Not supported yet, but realistic

| extension | what it needs | size |
|---|---|---|
| Typeable's `typeOf` | a `TypeRep` per type: an automatic instance for every type constructor, built from the type checker's types | medium |
| A catch-all instance (`instance Show a => Pretty a`) | instance lookup falling back to a type-variable head | medium |
| QuantifiedConstraints | contexts with `forall` in instance heads; dictionary functions as dictionary fields | medium-large |
| Arrows (`proc` notation) | the desugaring to `arr`/`>>>`/`first` | medium, rarely used |
| Real concurrency | a thread-safe runtime: thunk update and the allocation paths under SBCL threads | large |
| GHC.Generics' `Rep` | type families exist now; the derived `from`/`to` and the representation types | large |

### 5. Not realistic here

- **TemplateHaskell / QuasiQuotes**: compile-time evaluation of Haskell
  producing syntax trees.  In principle possible (the compiler is in
  Lisp and can run compiled code), but it needs the whole TH AST library
  and a staging story; out of scope.
- **GHC's runtime features**: `+RTS` options, profiling, the GHC event
  log, `GHC.Stats`, sparks (`par` is ignored), weak pointers with
  finalizers' timing, stable names.
- **The package ecosystem as Cabal sees it**: Yale Haskell compiles
  source modules; libraries are added as modules under `lib/haskell98`.

## What running "modern Haskell" needs now

The probes say the language is mostly there.  The gaps that real
programs hit first are, in order:

1. **Libraries.**  Each modern program imports a few packages beyond
   base.  text, bytestring, containers, mtl, transformers, stm and
   deepseq exist now (some as approximations); vector, unordered-
   containers, aeson, optparse-applicative, filepath, directory,
   process, time do not.  These are mostly Haskell and could be ported
   module by module (GHC-specific internals are the obstacle: vector's
   primitive arrays map onto Yale's MutArr).
2. **Record update of a duplicated field** (`r { name = x }` with
   `name` in several types) needs the record's type; construction,
   patterns and `r.name` work.
3. **Performance of the String-backed Text and ByteString**: a real
   packed representation (Lisp strings and `(unsigned-byte 8)` vectors)
   would keep the API and fix the cost.
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
