# Plan: Haskell 98 and Haskell 2010 conformance

The haskell98 dialect aims at the Haskell 98 Report (revised) and, with
`--haskell2010`, the Haskell 2010 Report.  Three tools measure it:

| Tool | What it checks |
|---|---|
| `tests/run-tests` | the regression suite (208 tests on 2026-10-09); `.flags` files give compiler options, e.g. `--haskell2010` |
| `tools/conformance/h2010-exports.py` | every library module of the 2010 Report (Part II, from `ref/haskell2010-report`, `make ref`) imports with exactly the Report's export list |
| `tools/conformance/nofib.py` | nofib's `imaginary` and `spectral` programs against their expected output (`--modern-prelude`, as nofib is written for GHC) |

## Status (2026-10-09)

**Libraries:** all 30 modules of the 2010 Report pass
`h2010-exports.py`. Done in this pass:
- Prelude entities re-exported where the Report lists them
  (`Control.Monad`, `Data.Char`, `Data.Maybe`).
- `System.IO`: `hSetFileSize`, `hTell`, `hIsTerminalDevice`,
  `hSetEcho`/`hGetEcho`, `hShow`.
- `System.IO.Error`: `mkIOError`, `annotateIOError`, `IOErrorType` and
  its values, `catch`, `try`.
- `rangeSize` as an `Ix` method.
- `Foreign.ForeignPtr`, `Foreign.StablePtr`, `Foreign.C.Error`,
  `IntPtr`/`WordPtr`, `finalizerFree`, the remaining
  `Foreign.C.Types`/`Foreign.C.String` names.

**Language, Haskell 2010 changes:**

| Change | Status |
|---|---|
| FFI (chapter 8) | yes (doc/FFI.md), with `"wrapper"` callbacks and `foreign export` (2026-10-14; an export is reached through `&name`, not by the C linker) |
| Hierarchical modules | yes |
| Pattern guards | yes |
| Empty data declarations | yes |
| Relaxed dependency analysis (signatures split binding groups) | yes |
| DoAndIfThenElse | yes (also accepted in 98 mode) |
| LineCommentSyntax (`-->` is an operator) | yes |
| Fixity resolution (negation at precedence 6) | yes |
| `LANGUAGE` pragmas | ignored, as allowed |
| n+k patterns removed | error with `--haskell2010` |
| Datatype contexts removed | error with `--haskell2010` |
| `catch` not in the Prelude | yes with `--haskell2010` |

**Language, Haskell 98 fixes in this pass:**
- A module with an empty body.
- The empty context `() =>`.
- Re-exporting a Prelude data type with its constructors.
- Derived `Show` of types with more than 6 constructors no longer
  needs `Read`.

**nofib:** 68 pass, 4 known deviations, 3 skipped, no failures
(2026-10-10, after simple's fix; 45 and 25 skipped before CPP and the
base libraries).
- **Known deviations:**
  - mandel: `hSetBinaryMode`.
  - minimax: correct but slow at its size.
  - secretary: a different random generator.
  - sphere: 64-bit `Int` wrap-around.
- **Skips:** three programs have no `Main`, or no expected output that
  GHC can make.
- **CPP** (`--cpp`, `{-# LANGUAGE CPP #-}`; src/compiler/parser/cpp.mumble):
  - The 14 hartel programs pass through it. Their `Fast2haskell.hs` uses
    GHC's unboxed primitives, so tools/conformance/Fast2haskell.hs, a
    `Data.Bits` stand-in, is included instead.
  - calendar and knights pass through it too.

## GHC extensions and modern base (2026-10-10; 2026-10-11)

**2026-10-11:** the extension work is now recorded in
**doc/plans/GHC-EXTENSIONS.md**: 74 probes (GHC2021, the common
extensions beyond it, and modern libraries), 69 passing; GADTs,
TypeFamilies, DataKinds, PatternSynonyms, Overloaded* and the rest; what
is supported exactly, permissively or by approximation, and what is
left.  The list below is the state of 2026-10-10.

`tools/conformance/extensions.py` runs 27 small programs, each using a
GHC extension or a modern-base idiom, and compares them with GHC's output:
**all 27 pass**.

**Accepted:**
- **Syntax:** BangPatterns, LambdaCase, MultiWayIf, TupleSections,
  BinaryLiterals, NumericUnderscores, InstanceSigs (signatures dropped),
  KindSignatures (kinds inferred), NamedFieldPuns, RecordWildCards,
  GADTSyntax (ordinary data types only), StandaloneDeriving (same module),
  EmptyCase, TypeApplications.
- **Types:**
  - FlexibleContexts: reduced through instances.
  - FlexibleInstances and TypeSynonymInstances: one instance per class
    and type constructor; a use must match the head.
  - Multi-parameter classes with fundeps and superclasses.
  - ScopedTypeVariables: a forall's variables, in inner signatures and
    annotations.
  - ExistentialQuantification: hidden dictionary fields, rigid type
    variables.
  - RankNTypes: polytypes as arguments and fields, with or without a
    context (`forall s. Shape s => s -> Double`; the value takes the
    dictionaries first).  An argument for a polytype with a context is
    checked to be polymorphic enough; one without a context is not.
    A pattern variable bound to a polytype field is polymorphic.
- **Deriving:** Functor, Foldable, Traversable; GeneralizedNewtypeDeriving
  (the underlying instance must have no context and come from another
  module).
- **The Functor-Applicative-Monad hierarchy:** while PreludeModern is
  loaded, `Monad m` implies Functor and Applicative, and a Monad
  instance's return defaults to pure.

**Libraries** (beyond the Report's):
- base: Data.Foldable, Data.Traversable, Data.Monoid, Data.Ord,
  Data.Either, Data.Tuple, Data.Functor, Data.Functor.Identity,
  Data.Bifunctor, Data.IORef, Data.STRef, Control.Monad.ST,
  System.IO.Unsafe, Control.Monad.IO.Class, Text.Printf.
- array: Data.Array.ST, .IO, .MArray, .Base, .Unboxed, .IArray.
- containers: Map, Set, IntMap, IntSet, Sequence, Tree, and the
  `.Strict`/`.Lazy` modules.
- pretty: Text.PrettyPrint.
- transformers: State, Reader, Writer, Maybe, Except.
- mtl: State, Reader, Writer, Except.

**Known gaps** (2026-10-11; see GHC-EXTENSIONS.md):
- Escape checks for existential and rank-N type variables, and local
  type refinement for GADTs (both permissive).
- The Strict extension (ignored).
- QuantifiedConstraints, Arrows, Template Haskell,
  Typeable's typeOf, Generic representations.

## Next

1. **simple's space leak:** fixed (2026-10-10, bench/RESULTS.md).
   The cause was that single-constructor patterns did not evaluate the
   value. Making them strict fixed it. A lazy pattern binding
   `let (a, b) = e` can still keep `e` alive through the thunk for `a`
   (GHC's collector short-cuts these, ours does not); selecting eagerly
   when the tuple is evaluated is GHC-OPTIMIZATIONS.md's item for that.
2. **Binary I/O** (base, not the Report): `openBinaryFile`,
   `withBinaryFile`, `hSetBinaryMode`, `hGetBuf`/`hPutBuf`. This needs a
   Latin-1 (byte) external format for handles (`prim.open-file`), and it
   unblocks mandel.
3. **CPP:** done (src/compiler/parser/cpp.mumble), as a built-in cpphs-like
   preprocessor.
   - Directives: `#include`, object- and function-like `#define`,
     `#if`/`#elif` with C's operators and `defined`, `#ifdef`, `#error`.
   - Flags: `--cpp`, `-D`, `-I`.
   - `{-# LINE #-}` keeps line numbers after an include, and included
     files are dependencies in the unit cache.
   - Not yet: `##` and `#` in macro bodies, and Cabal's
     `MIN_VERSION_pkg(...)` macros (they are 0 for now).
4. **Text.Printf:** done, with **Text.PrettyPrint** (`pretty`'s
   HughesPJ). Both are nhc98's Haskell 98 versions, imported by
   tools/gen/import-nhc98-libs.py, and the output matches GHC's.
   last-piece passes.
   - Fixed for them: pragma names are not case-sensitive
     (`{-# Language CPP #-}`), a class may be exported by its bare name,
     and empty top-level declarations (`x :: T;` at a line's end) parse.
5. **Monad with an Applicative superclass** in `--modern-prelude`
   (MICROCABAL.md step 2b).
   - **Foldable/Traversable:** done. They are PreludeModern's, and in a
     user module under `--modern-prelude` they replace the Prelude's list
     functions (`length`, `sum`, `elem`, `mapM_`, `mapM`, ...).
   - For that, symbol-table.mumble's `*foldable-prelude-names*` leaves
     those names out of the implicit Prelude, and lets PreludeModern's win
     over an explicit `import Prelude` or `Data.List`.
   - The list instance's methods are `Inline`, so code at list type is
     the same as with the Haskell 98 Prelude (nofib times unchanged).
   - New base modules: Data.Foldable, Data.Traversable, Data.Monoid,
     Data.Ord, Data.Either, Data.Tuple, Data.Functor, Data.Bifunctor,
     Data.IORef, Control.Monad.ST (.Strict, .Lazy), Data.STRef,
     System.IO.Unsafe.
   - runST has the Haskell 98 type `ST s a -> a`, as there are no rank-2
     types.
   - Imports and hiding lists can now name a class method or field by
     itself (`import Data.Foldable (toList)`).
   - **containers:** Data.Map, Data.Set, Data.IntMap, Data.IntSet,
     Data.Sequence and Data.Tree. They are version 0.3.0.0 as nhc98 ships
     it (Haskell 98 with CPP), imported by tools/gen/import-containers.py
     without Data.Typeable.
     - Data.Graph (2026-10-14): Hugs's, with containers 0.7's
       `NECyclicSCC` (and `CyclicSCC` as a pattern synonym) and
       `reverseTopSort`; output matches GHC 9.14's
       (tests/haskell98/lib/data-graph.hs).
     - Still missing: the `.Strict` modules.
   - **process** (2026-10-14): `createProcess` with pipes, `proc`/`shell`,
     `cwd`/`env`, `waitForProcess`, `getProcessExitCode`,
     `terminateProcess`, `withCreateProcess`, `callProcess`,
     `spawnProcess`, the `read*Process*` family (standard error
     captured), over uiop's launch-program (tests/haskell98/system/
     process.hs, checked against GHC).  Not there: process groups,
     signals other than terminate, `Pid`.  Our own buffered output is not
     flushed before a child runs, as GHC's is not; under a pipe, GHC's
     block-buffered stdout can then appear after the child's.
6. **Multi-parameter type classes:** done (e19c23a, 9ffb5a5), with
   functional dependencies, instance contexts, recursive bindings and
   interface files. Tests are in tests/haskell98/language/mptc-*.
   Left to do:
   - superclasses of a multi-parameter class (rejected);
   - FlexibleInstances heads, such as `C [Char] t` (rejected).
7. **`foreign export` and `"wrapper"` imports:** done (2026-10-14,
   doc/FFI.md; tests/haskell98/ffi/callback*.hs). Exports are not linker
   symbols: C reaches them through a `FunPtr`.
8. **A broader corpus:** nofib `real`, then the programs of
   REAL-WORLD-TARGETS.md.
