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
| FFI (chapter 8) | yes (doc/FFI.md); no `foreign export` or `"wrapper"` |
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

**nofib:** 63 pass, 5 known deviations, 7 skipped, no failures
(2026-10-10; 45 and 25 skipped before CPP and the base libraries).
- **Known deviations:**
  - mandel: `hSetBinaryMode`.
  - minimax: correct but slow at its size.
  - secretary: a different random generator.
  - sphere: 64-bit `Int` wrap-around.
  - simple: exhausts the heap; see below.
- **Skips:** libraries we lack: Data.Array.ST/Data.Array.Base (kahan,
  dom-lt) and mtl's Control.Monad.Trans (cryptarithm2, lambda). The other
  three have no `Main`, or no expected output that GHC can make.
- **CPP** (`--cpp`, `{-# LANGUAGE CPP #-}`; src/compiler/parser/cpp.mumble):
  - The 14 hartel programs pass through it. Their `Fast2haskell.hs` uses
    GHC's unboxed primitives, so tools/conformance/Fast2haskell.hs, a
    `Data.Bits` stand-in, is included instead.
  - calendar and knights pass through it too.

## Next

1. **simple's space leak.** It compiles in seconds but its run fills
   4 GB with both back ends.
   - Suspect the selector-thunk leak: lazy tuple patterns such as
     `let (a, b) = e` keep `e` alive through the thunk for `a`. GHC's
     collector short-cuts these; ours does not.
   - Find it with a smaller input, then either evaluate selector thunks
     during GC (hard on a Lisp GC) or select eagerly when the tuple is
     already evaluated.
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
     - Still missing: Data.Graph, which needs Data.Array.ST, and the
       `.Strict` modules.
6. **Multi-parameter type classes:** done (e19c23a, 9ffb5a5), with
   functional dependencies, instance contexts, recursive bindings and
   interface files. Tests are in tests/haskell98/language/mptc-*.
   Left to do:
   - superclasses of a multi-parameter class (rejected);
   - FlexibleInstances heads, such as `C [Char] t` (rejected).
7. **`foreign export` and `"wrapper"` imports** (doc/FFI.md).
8. **A broader corpus:** nofib `real`, then the programs of
   REAL-WORLD-TARGETS.md.
