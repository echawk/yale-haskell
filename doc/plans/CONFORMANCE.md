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

**nofib:** 45 pass, 5 known deviations, 25 skipped, no failures.
- **Known deviations:**
  - mandel: `hSetBinaryMode`.
  - minimax: correct but slow at its size.
  - secretary: a different random generator.
  - sphere: 64-bit `Int` wrap-around.
  - simple: exhausts the heap; see below.
- **Skips:** 6 use CPP `#include` (`spectral/hartel/*`), 1 uses `#define`,
  1 uses Text.Printf (last-piece), 1 uses Control.Monad.Trans (lambda),
  and the rest have no `Main` or use GHC extensions.

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
3. **CPP** (`{-# LANGUAGE CPP #-}`, `#include`, `#define`, `#if`) would
   unblock 7 nofib programs and much real code. Use `cpp -traditional`
   when present, as GHC does, or a small built-in subset.
4. **Text.Printf** (base) for last-piece and real code. It needs a
   class-based variadic `printf`, which Haskell 98 can express.
5. **Monad with an Applicative superclass** in `--modern-prelude`
   (MICROCABAL.md step 2b), and **Foldable/Traversable**.
6. **Multi-parameter type classes:** done (e19c23a, 9ffb5a5), with
   functional dependencies, instance contexts, recursive bindings and
   interface files. Tests are in tests/haskell98/language/mptc-*.
   Left to do:
   - superclasses of a multi-parameter class (rejected);
   - FlexibleInstances heads, such as `C [Char] t` (rejected).
7. **`foreign export` and `"wrapper"` imports** (doc/FFI.md).
8. **A broader corpus:** nofib `real`, then the programs of
   REAL-WORLD-TARGETS.md.
