# Changelog

Version numbers are MAJOR.MINOR.FEATURE.FIX:

- **major**: 4.0.0 is reserved for the release in which no mumble code is
  left (doc/plans/MUMBLE-TO-CL.md); until then it stays 3;
- **minor**: a milestone: a substantial new capability, or a change that
  breaks programs or interfaces that compiled before (marked
  **breaking** here);
- **feature**: a release of accumulated small features, libraries and
  extensions (one release for a batch of work, not one per change);
- **fix**: a release of bug and conformance fixes only.

3.0.1.0 to 3.0.15.0 were first numbered 3.1.0 to 3.15.0 (and 3.0.1.1 was
3.1.1); commit messages of that time use the old numbers.

The version is `*haskell-compiler-version*` in
`src/compiler/top/globals.mumble` and `:version` in `yale-haskell.asd`;
both change together, with an entry here.  The version is part of every
compiled interface, so a new version recompiles cached units.

## Unreleased

- The time package, ported (version 1.15: calendars, local time, time
  zones, formatting and parsing, ISO 8601), replacing the minimal
  Data.Time.  Typed Template Haskell (`[|| ||]`, `$$( )`) on the untyped.
  Pattern synonyms: a signature types the arguments (also in other
  modules, through typing functions in the template), and a synonym with
  views can be used in a lambda.  Signatures on tuple pattern
  components; a lambda's `->` inside a view pattern's expression;
  `{-#UNPACK#-}` under MagicHash; a package's default extensions in the
  dependency scan (MagicHash's implicit GHC.Exts); happy's generated
  parsers' GHC-only `#error`.  MicroCabal: happy and alex build and
  generate `.y`/`.x` modules; internal libraries; renamed
  reexported-modules; data files kept on install.

- Libraries for packages on the way to Agda and jni: the binary package
  (Data.Binary, .Get, .Put, .Builder, with binary's encodings),
  Data.Text.Encoding (and .Error, Data.Text.Lazy.Encoding),
  Type.Reflection, Data.Type.Coercion, GHC.TypeNats, GHC.TypeLits'
  classes and singletons (no type-level literals), GHC.OverloadedLabels,
  Control.Exception's SomeAsyncException and blocked-thread exceptions,
  TBQueue, and Hashable ThreadId.  `~~` and qualified equality
  operators in contexts.  MicroCabal patches for async and boring.

- Parallelism: Control.Parallel (`par`, `pseq`) and
  Control.Parallel.Strategies (the parallel package's interface).  With
  `+RTS -N[n]` (or `GHCRTS`) sparks run on a pool of lparallel worker
  threads, and thunk evaluation is thread-safe from the first spark;
  `getNumCapabilities` and `numCapabilities` report n.  `+RTS ... -RTS`
  options are no longer passed to the program.  Tests in
  tests/haskell98/parallel/ (the test runner reads a test's program
  arguments from its `.args` file).

- Refinement types (milestone 2 of doc/plans/LIQUID-HASKELL.md):
  `--liquid` checks top-level functions against `{-@ @-}` refined
  signatures, type aliases and `assume`s with Z3 (first-order Int and
  Bool code); yale-liquid is in the image, without its Prolog
  cross-check, and `make liquid-test` runs its tests.

- Deriving: classes of type constructors through a newtype (Bifunctor
  (Biap bi)), with the field's flexible context (Ord1 (bi a)); derived
  Functor, Foldable and Traversable with a context on an application
  (Functor (bi a)); derived Read for such fields.
- A class method with its own multi-parameter constraint keeps the class's
  type variable as the carrier (profunctors' (#.)).
- A synonym for a polytype as an argument's type ((p :-> q) -> ...), and
  as a constructor field's type, also when defined in the same module.
- RankNTypes: a polytype inside another that uses its type variables
  (forall r. (forall x y. p x y -> r x y) -> r a b) keeps them apart; a
  lambda given for a polytype argument has polymorphic variables where
  the polytype has polytype arguments; f $ x with the Prelude's $ is
  typed as f x, so x may be given for a polytype (Copastro $ \n -> ..).
- Derived Functor over function types (r -> a, (a -> b) -> t) and
  polytypes (Bazaar's forall f. Applicative f => (a -> f b) -> f t).
- A local binding's constraint on an application (Read (p b a)) is passed
  to the enclosing binding; Eq is taken from a given Ord at an
  application.
- In a module with base's Prelude, a Num instance whose type's Eq or Show
  needs more than it gives gets an error in that superclass slot (base's
  Num has none).
- transformers' Contravariant instances, and base's for the generic
  representation types and Alt.  bifunctors and contravariant build.
- Template Haskell: quoted names ('f, 'C, '(:), ''T, ''(~)) under
  TemplateHaskell or TemplateHaskellQuotes; in a type the tick is still
  DataKinds' promotion.  th-abstraction builds.
- Template Haskell: expression splices, $(e) and $x, of imported
  functions (milestone 2 of doc/plans/TEMPLATE-HASKELL.md); a name the
  module defines gets a stage-restriction error; --printers splices
  shows each splice's code.
- Template Haskell: quotes, [| e |] (or [e| |]), [p| p |] and [t| t |]
  (milestone 3): binders get newName's names, outer locals are lifted,
  global names are NameG's (the module's own too, inside a splice), and a
  splice inside a quote is part of its code.  The TH paper's power,
  printf and scoping example work.
- Template Haskell: declaration splices ($(e), $x, or an expression alone
  at the top level), [d| |] quotes, and reify of types, constructors and
  imported variables, the module's own types included (milestone 4).
- Multi-parameter superclasses (class (MonadReader r m, ...) =>
  MonadRWS r w s m) hold wherever the class does; a class without
  methods may have instances with contexts.  mtl's MonadRWS.
- Fixes for constraints on applications of type variables: two given
  constraints of one class (Show (f a), Show (g a)) each give their own
  dictionary (one was used for both); a subclass given (GOrd (f p))
  gives its superclasses; deriving infers such a context (Eq (f a)) as
  GHC does.
- A GADT match whose right-hand side needs no type refinement gets its
  type from the signature, so its constraints are not ambiguous.
- A pattern signature binds its type variables not in scope over the
  clause; GeneralizedNewtypeDeriving derives Enum through the field.
- Instances of a multi-parameter class overlap only when their types can
  be the same (synonyms expanded): GRead1 v (D1 d f) and GRead1 v (C1 c f).
- GADT constructors may have an operator's application as their result
  (Refl :: a :~: a); a context without forall in an argument
  ((a ~ b) => r); a fixity declaration for a type operator.
- A data family's constructors may be exported with it (F(C, ...)).
- Libraries: Data.Type.Equality; Control.Monad.Signatures and the
  transformers' liftCatch, liftCallCC, liftListen, liftPass; mtl's
  Control.Monad.RWS.Class; GHC.Generics' URec types and metadata classes
  (Datatype, Constructor, Selector, Fixity, ...); GHC.Exts' comparison
  primops and coerce; Bifunctor, Bifoldable, Bitraversable for tuples up
  to 7.  MIN_VERSION_template_haskell is 2.24, containers' 0.8.1.
- mcabal: a package's module that Yale Haskell's library has is not
  staged (a compatibility package's backport would hide the library's);
  a patch for transformers-compat.  transformers-compat and exceptions
  build.
- Template Haskell, milestone 1 (doc/plans/TEMPLATE-HASKELL.md): the
  library.  Language.Haskell.TH and its Syntax, Lib, Lib.Internal, Ppr,
  PprLib, Quote and LanguageExtensions modules are template-haskell
  2.24's, from GHC's sources (ghc-internal 9.1401.0, ghc-boot-th 9.14.1),
  with Q over IO.  Syntax is built with the Lib functions, run with runQ,
  and printed with pprint as GHC prints it.  GHC.Lexeme and GHC.Show
  (showMultiLineString and the other helpers) are new.
- deriving Lift (DeriveLift), with GHC's global names for the built-in
  constructors.
- Data.Typeable's TyCon knows its module (tyConModule, tyConPackage), so
  two types of one name from different modules differ.
- StandaloneDeriving of a built-in type: deriving instance ... => C (a, b).
- hiding (T) hides the type or class T (and a constructor T), not its
  constructors or methods, as the Report says; T(..) hides them all.
- doc/PACKAGES.md: how to run a program, build an executable, and build
  a cabal project with Hackage dependencies through mcabal.
- --haskell2010 and --modern-prelude given first select the Haskell 98
  image, as --ghc2021 does (they read the file as Haskell 1.2 before).
- Data.Data is base's: the class with gfoldl, gunfold, toConstr,
  dataTypeOf, dataCast1/2 and the gmap family; Constr, DataType and
  their functions; instances for base's types.  deriving Data writes the
  instance as GHC does (an empty one, as before, when a field's type has
  no Data instance).  Data.Typeable has gcast1 and gcast2.
- A forall in an arrow's result floats to the top (k :: Int -> forall a.
  Show a => a -> String), as in GHC.
- A local signature that mentions a scoped type variable generalizes its
  own variables, so a recursive use is polymorphic (SYB's everywhere and
  everything, with the function passed to gmapT or gmapQ).
- A class method with a rank-n argument (comonad's cohoist).
- Data.Semigroup: Functor, Foldable, Traversable for Arg; Bifunctor,
  Bifoldable, Bitraversable for Arg; Foldable, Traversable, Applicative
  and Monad for Min, Max, First, Last.  Control.Arrow: leftApp,
  ArrowMonad, Kleisli's Functor through MonadPlus.  comonad builds.
- An INLINE function that leads back to itself (a multi-parameter
  instance's method calling itself through its own dictionary, as
  indexed-traversable's FunctorWithIndex [Int] Tree) is a loop breaker,
  as in GHC; the optimizer unrolled it until memory ran out.
  indexed-traversable builds.  YALE_HASKELL_DEBUG=1 prints a backtrace
  when the stack or heap runs out.
- The lazy ByteString is its own type, as in bytestring (a newtype over
  the strict one), so a program may give instances for both;
  Data.ByteString.Lazy and .Lazy.Char8 are generated over it
  (tools/gen/lazy-bytestring.py), with bytestring's Int64 counts.
  Builder's toLazyByteString and lazyByteString use it; Parsec has
  Stream instances for lazy ByteString and lazy Text.
- base's Functor, Applicative and Monad instances for Dual, Sum,
  Product, First and Last; Proxy's Functor, Applicative, Alternative,
  Monad, Foldable, Traversable, Semigroup and Monoid; Contravariant for
  Reverse, Compose, Product and Sum.

- An expression annotation with an explicit forall that also mentions a
  variable scoped from an instance head now scopes its own variables
  over the expression (distributive's `coerce (fmap :: ...) :: forall
  a b f. ...`).
- transformers' instance contexts: Functor for ReaderT, StateT,
  WriterT, RWST, ExceptT and MaybeT needs only `Functor m`; ReaderT's
  Applicative and Alternative need `Applicative m` and `Alternative m`.

- A type family whose result is a type constructor may be applied to
  more arguments than it has (`Rep1 f a`, `F x Int` with `type instance
  F X = Maybe`); an equation's right-hand side may be a partial
  application.

- Type families: a constraint on a family application in a signature
  (`Size (Rep a) =>`) is kept and answers uses at that type; `h b` and
  an over-applied family application that does not reduce (`Rep1 g a`)
  unify as applications (`h` is `Rep1 g`); a family's arity is its
  declared one (not that of its first use, nor counting the arrows of
  its result kind); an equation's left-hand side may name a type
  constructor unapplied (`type R1 Box = Par`).
- Foreign.Ptr's IntPtr and WordPtr are newtypes, as in base.
- Foreign.C.Types' types are newtypes, as in the Report and base (they
  were synonyms of the Data.Int and Data.Word types), so a program may
  give instances for CInt and Int32 both; CBool, CUSeconds and
  CSUSeconds are new.  The FFI passes them as the underlying types.
  System.Posix.Types' Fd is over CInt.

- A multi-parameter instance's types may be any types
  (FlexibleInstances: `instance FoldableWithIndex [Int] Tree`).
- Data.Tuple's Solo (MkSolo, the pattern Solo, getSolo) with base's
  instances.

- Control.Applicative has ZipList, WrappedArrow and asum, and exports
  liftA2 as Applicative's method.

- Yale Haskell's containers library is containers 0.8.1, its source
  unchanged (tools/gen/import-containers.py; it was nhc98's 0.3 port):
  the whole modern API of Data.Map, IntMap, Set, IntSet, Sequence (with
  its pattern synonyms), Tree and Graph, the Merge modules and
  Data.Containers.ListUtils.  mapcount runs at 1.7x GHC -O2 (was 2.1x).
- Array has base's Foldable and Traversable instances, and, as in base,
  no datatype context (the Report's has `Ix a`).
- The real containers 0.8.1 compiles and runs unchanged (with
  DEFINE_PATTERN_SYNONYMS), which brought these fixes:
  - `module Prelude` in an export list re-exports base's Prelude with
    `--modern-prelude` (PreludeModern's names too), and not Ix, which
    neither the Report's nor base's Prelude exports;
  - `C(..)` re-exports the members of C in scope (it stopped at the
    first member not in scope);
  - `import M hiding (x)` hides x wherever M exports it, as a class
    method too, and for every group that has it;
  - in `--modern-prelude`, `Prelude.foldr` and the other Foldable names
    are Foldable's when qualified too;
  - `(<$)` is a Functor method, as in base (not exported by the Haskell
    98 Prelude);
  - pattern synonyms: operators (`pattern (:<|) :: ...`, `pattern x :<|
    xs <- ...` with an infix builder clause), their fixities, use as
    infix patterns, and bundling with a type in export lists (`Seq
    (Empty, (:<|), (:|>))`, `T (.., P)`), so importing `T(..)` brings
    them;
  - Data.Semigroup's stimesIdempotent(Monoid); Control.DeepSeq's
    NFData1 and NFData2, and NFData for the sized integers, Ratio,
    Complex, NonEmpty, Identity, Const and Proxy; Read1 NonEmpty.

## 3.0.15.0 (2026-10-17)

- Read has base's `readPrec` and `readListPrec` methods: an instance
  defines `readsPrec` or `readPrec`.  ReadPrec is a reader given the
  precedence (Int -> ReadS a, PreludeCore); Text.ParserCombinators
  .ReadPrec's operations are over it.  The Haskell 98 Prelude does not
  export these names (a program may still define its own).  Text.Read
  exports them with `Lexeme(..)`, `lexP`, `parens`,
  `readListPrecDefault`; new modules GHC.Read (`paren`, `list`,
  `expectP`, `choose`, `readField`, ...) and Text.Read.Lex.
- `Q.T(..)` in an export list (T imported qualified as Q) exports the
  constructors in scope as Q.C; it was reported as not exported.

## 3.0.14.0 (2026-10-17)

- base's Functor, Applicative, Monad, Foldable and Traversable
  instances for Complex (with `--modern-prelude`), and Contravariant
  Proxy.

## 3.0.13.0 (2026-10-17)

- `deriving Generic1` makes the instance for the type constructor
  (`Generic1 (T a)` for `T a b`), as GHC; it was for the whole type.
- Data.Monoid's Alt and Ap; Control.Monad.Zip.

## 3.0.12.0 (2026-10-17)

- `yale-haskell build` failed about one time in five with a memory
  fault while saving (SBCL on macOS, after a thread with a large stack).
  It now compiles in one process and saves in a second that never has
  one (src/cli/cli.lisp).
- Two modules imported qualified under one name that both export x:
  only a use of the qualified x is an error (Haskell 98 5.5.2); the
  imports were rejected.
- `(:*:)(..)` and other operator type constructors in import and export
  lists.
- GHC.Generics has the representation types (U1, Par1, K1, M1, :+:,
  :*:, :.:, ...) and Rep; derived Generic instances are still empty.
- Data.Functor.Reverse.
- MicroCabal backend: `tools/microcabal/patches/NAME.patch` is applied
  to a package's staged sources (tagged's Proxy comes only from a
  GHC-only import).  Defining `__GLASGOW_HASKELL__` for every package
  was measured and builds fewer packages (11 against 13 of 43), so it
  stays off.

## 3.0.11.0 (2026-10-17)

- Complex as in base: no datatype context, and `mkPolar` and `cis` need
  only Floating, `conjugate` Num, `realPart` and `imagPart` nothing
  (colour's `okLCh :: Floating a => ...` was "too general").
- A multi-parameter superclass (`class HasSetter t b => HasUpdate t a
  b`) crashed the compiler; it is accepted and dropped (multi-parameter
  classes have no superclasses here).

## 3.0.10.0 (2026-10-17)

- Foldable has base's `fold` and `foldMap'` methods (Data.Foldable
  exports them; the Prelude does not, as base's does not).  An instance
  defining `fold` (tagged) was an error.
- New modules: Data.Functor.Compose, Data.Functor.Product,
  Data.Functor.Sum, Control.Monad.ST.Lazy.Unsafe.

## 3.0.9.0 (2026-10-17)

- New modules: Data.Bifoldable1, Data.Functor.Contravariant,
  Control.Monad.Trans.Select; Control.Concurrent's forkOSWithUnmask and
  forkOnWithUnmask, and rank-2 forkIOWithUnmask.

## 3.0.8.0 (2026-10-17)

- Layout (Haskell 98 report 10.3): a declaration block (`where`, `let`,
  a class or instance body) whose first token is not indented past the
  enclosing block is empty.  `instance C T where` followed by a
  top-level declaration took that declaration as a method.
- Exceptions of a program's own types: `instance Exception T` with the
  default methods, thrown and caught by type (Exception has base's
  Typeable superclass, and the value travels as a Dynamic).
  `Handler` and `catches`, `catchJust`, `handleJust`, `tryJust`,
  `AsyncException`, `AssertionFailed`, rank-2 `mask`.  A superclass
  dictionary of a built-in Typeable instance was the bare builder.
- With `--modern-prelude`, `import Prelude (x, y)` limits base's Prelude
  names (PreludeModern) to the list too, and may name them (`Monoid`,
  `<>`); a module could not define its own `<>`.
- An instance whose equality constraints make its head non-linear
  (`instance (a ~ b) => Each (a, b) ...`) is accepted; an equality in a
  signature with other constraints crashed the compiler.
- New modules: Data.Foldable1, Control.Monad.Trans.Identity,
  Control.Monad.Trans.Accum.

## 3.0.7.0 (2026-10-17)

- An export list may name an entity by a qualified name (`module M
  (C.choice) where import qualified A as C`); it is exported under its
  own name, as Haskell 98 5.2 says.  It was not exported.
- Type synonyms for polytypes (`type Lens s t a b = forall f. Functor f
  => ...`) in signatures: the forall and its context are lifted to the
  signature (it crashed the type checker).
- New modules: Data.Bifoldable, Data.Bitraversable, Data.Functor.Constant
  and Control.Applicative.Lift (transformers), Foreign.C.ConstPtr,
  GHC.List, GHC.Arr, Control.Monad.ST.Unsafe, Data.ByteString.Short.

## 3.0.6.0 (2026-10-17)

From the Hackage survey (doc/plans/MICROCABAL.md):

- `module M () where`: an empty export list exports only instances (it
  did not parse).
- `{-# INLINE [0] f #-}`, `[~1]` and `CONLIKE`: GHC's phase control is
  accepted and ignored.
- Nullary constraints: `HasCallStack =>`, and any synonym of `()` used
  as a constraint (`type Partial = HasCallStack`), mean no constraint.
- Equality constraints in signatures, `(a ~ b, C a) => ...`: a type
  variable equal to a type is replaced by it (an equality between two
  other types is dropped).  In an instance context too: `instance a ~ Char =>
  IsString (W [a])` is the instance for `W [Char]`.
- New modules: GHC.Stack (empty call stacks), Data.Functor.Classes
  (Eq1, Ord1, Show1, Read1 and the binary classes, with base's ReadS
  methods).
- `liftA2` is an Applicative method, as in base (an instance may define
  it instead of `<*>`); Bifunctor instances for Const and 3- and 4-tuples;
  Text.Read exports Read; Data.Coerce exports Coercible.

## 3.0.5.0 (2026-10-17)

- `yale-haskell build FILE [-o EXE]`: a standalone executable (the image
  with the program loaded, saved by SBCL) that runs Main.main with all
  its arguments.  MicroCabal's Yale backend builds packages' executables
  with it: alex 3.5.4.2 builds from Hackage and generates the same
  scanners as a GHC-built alex on its 46 test grammars.
- A program whose stdout reader goes away (`prog | head`) fails with an
  IOError `<stdout>: hPutChar: failed (Broken pipe)`, status 1, as GHC's
  does, instead of a Lisp message; a broken pipe at the final flush
  exits 141 quietly.
- `import M (pattern C)` for a data constructor C (GHC); `import
  GHC.Exts (Int(I#))`: GHC.Exts exports Int, Word, Char, Double, Float,
  and a boxing constructor in an import list is accepted.
- DatatypeContexts, part of GHC's Haskell2010 and Haskell98 languages:
  a datatype context is accepted when it is on.
- `#include "MachDeps.h"` and `"ghcconfig.h"` find stand-ins for GHC's
  headers in `$HASKELL_LIBRARY/include`.
- A local binding without a signature whose class constraints are on an
  undecided type family application (`Ord (Item l)` under
  OverloadedLists) is not generalized over its type variables; it
  failed with an internal error ("Type checker screwed a method
  placeholder").
- MicroCabal backend: `$YALE_CPP_OPTIONS` adds CPP options to every
  package (`-D__GLASGOW_HASKELL__=906` for code that insists on GHC).

## 3.0.4.0 (2026-10-17)

- `--ghc2021` and `--ghc2024`: GHC's language standards, their
  extensions on in every module, with `--modern-prelude`.  `-X NAME`
  (`--extension`) turns on an extension in every module.
- A language name in a LANGUAGE pragma or a package's default-language
  (GHC2021, GHC2024, Haskell2010, Haskell98) stands for its extensions,
  and `NoNAME` turns an extension off.

## 3.0.3.0 (2026-10-17)

- DataKinds type-level lists: `'[]`, `'[a]`, `[a, b]`, `t ': ts` (and
  `t : ts`), as the empty types PromotedNil and PromotedCons
  (parser/type-parser.mumble).
- Kind-annotated class parameters after the first,
  `class C (n :: Nat) (ts :: [Type]) r`.
- ScopedTypeVariables in multi-parameter instances: the head's type
  variables scope over the methods, also when named like the class's
  (class variables are now substituted simultaneously).
- AllowAmbiguousTypes: a method whose type mentions none of the class's
  variables (`name :: String` in `class Name a b`), chosen by type
  applications; a type variable only a constraint mentions is shared by
  the binding's body, its signature check and its dictionary, and an
  instance's dictionary binds it from the instance head.
- hlist.hs (heterogeneous lists with GADTs, DataKinds, a closed type
  family, fundeps and type applications) runs: tests/haskell98/language/
  hlist.hs.

## 3.0.2.0 (2026-10-17)

- MicroCabal backend (tools/microcabal/): `tools/microcabal/mcabal
  install PKG` fetches a Hackage package (Stackage's versions) and
  installs it, with `-r` its dependencies, into a package database that
  `--package-db` reads.  The backend and its patch to MicroCabal live
  here; the clone in ref/MicroCabal is not changed.
  `tools/microcabal/hackage-survey.sh` tries 43 popular libraries: 2
  build so far, and doc/plans/MICROCABAL.md lists what stops the rest.

## 3.0.1.1 (2026-10-17)

- `--help`, `--version` and `--numeric-version` crashed after printing
  (a memory fault, status 1) with a program stack of 64 MB or more, the
  default 512 included: an exit from the worker thread now flushes the
  output and exits at once (src/cli/cli.lisp).  `make test` checks the
  three options' exit status.

## 3.0.1.0 (2026-10-17)

- Module search path: `-i DIR` (repeatable) and `$YALE_HASKELL_PATH`.
- Installed packages: `--package-db DIR` (and `$YALE_HASKELL_PACKAGE_DB`)
  names directories of packages (`NAME-VERSION/src`, `include`,
  `yale-package`); a package's modules are found, compiled with its own
  default extensions, cpp-options and include-dirs, and its version
  answers `MIN_VERSION_name` (src/compiler/csys/packages.mumble).
- `--numeric-version`.
- The typed core (`--emit typed`), from before the version was
  declared, is in this release too.

## 3.0.0 (2026-10-17)

The revival of Y2.0.5 (1994) as a Haskell 98 / Haskell 2010 compiler on
SBCL, declared 3.0.0.  It covers the work recorded in doc/REVIVAL-PLAN.md
and doc/plans/: Haskell 98 and 2010 conformance (nofib 69 + 40 programs),
around 100 GHC extensions (tools/conformance/extensions.py: 101 of 104),
the modern base libraries (Applicative/Monad, Foldable/Traversable,
mtl, containers, text, bytestring and more), the GRIN back end and the
optimizations of bench/RESULTS.md, the FFI, the interactive system, a
unit cache, and real programs compiled unchanged (cubicaltt, happy,
darcs, xmonad's core, husk, optparse-applicative's tests).
