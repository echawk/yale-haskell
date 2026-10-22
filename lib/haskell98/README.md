# Haskell 98 and 2010 libraries

This tree is the Haskell 98 counterpart of `lib/haskell-1.2/`.  It is
built as a separate *dialect*: `make` compiles both Preludes and saves
one executable per dialect, and `bin/yale-haskell --haskell98` selects
this one.  Besides the Report's libraries it holds base and the other
boot-style packages under GHC's module names (about 450 modules), so
that Hackage packages built with MicroCabal (doc/PACKAGES.md) find them.

| Path | Contents |
|---|---|
| `prelude/` | the Haskell 98 Standard Prelude, as the Report gives it, with the deviations below |
| `<Module>.hs`, `<Module>.hu` | the H98 standard libraries: `List`, `Char`, `Maybe`, `Numeric`, `Ratio`, `Complex`, `Ix`, `Array`, `IO`, `System`, `Directory`, `Time`, `Locale`, `CPUTime`, `Random`, `Monad`; `Dialogue` (Yale: Haskell 1.2 stream I/O, `appendChan stdout ... abort done`); `PreludeModern` (GHC base's Prelude names, for `--modern-prelude`; also the hidden classes `IP` of ImplicitParams and `TypeEquality` of equality constraints) |
| `*Prims.hi` | primitives: Haskell names for Lisp functions (`src/base/`, `src/runtime/`) |
| `Control/`, `Data/`, `Foreign/`, `GHC/`, `System/`, `Text/`, `Numeric/`, `Debug/`, `Unsafe/`, `Type/`, `Test/` | base, containers, text, bytestring, mtl, transformers, stm, deepseq, parsec, time, process, unix, QuickCheck, ... (the packages listed as built in by `tools/microcabal/Yale.hs`) |
| `Language/` | Template Haskell's library (doc/plans/TEMPLATE-HASKELL.md) |
| `include/` | C headers packages `#include` (HsBaseConfig.h, MachDeps.h, ...) |

Reference material: the Report (`ref/haskell-report`, branch `h98`) is
the specification; Hugs (`ref/hugs98`, `libraries/hugsbase/Hugs/Prelude.hs`
and `packages/haskell98`) is the reference implementation.  See
`ref/README.md` for licensing when borrowing code.

Anything here must compile with the compiler as it is; a definition
that needs a feature Yale Haskell lacks is left out (or approximated,
and says so in a comment) until the feature lands.

## How the Prelude is organised

The compiler gives every user module the *symbol table* of module
`Prelude` (everything in scope there, not just its export list), so
`prelude/Prelude.hs` imports only the names the H98 Prelude exports.
A program may therefore define `nub`, `partition`, `(!)`, `elems`,
`showInt`, ... without hiding anything.  The rest lives in internal
modules that the libraries re-export:

| Library | Defined in |
|---|---|
| `List` | `List.hs` (Report code) |
| `Maybe` | `Maybe.hs` (Report code) |
| `Char` | `prelude/PreludeChar.hs`, `prelude/PreludeText.hs` (`readLitChar`, `showLitChar`, `lexLitChar`) |
| `Numeric` | `prelude/PreludeNumeric.hs` (Report code; the Prelude's `Show`/`Read` instances use it) |
| `Ratio` | `prelude/PreludeRatio.hs` |
| `Complex` | `prelude/PreludeComplex.hs` |
| `Ix` | class (with `rangeSize`) in `prelude/PreludeCore.hs` |
| `Array` | `prelude/PreludeArray.hs` |

Library modules do not repeat the Prelude names in their export lists
(e.g. `Maybe` does not re-export `Maybe(..)` and `maybe`): this compiler
rejects re-exporting an entity it gets from the Prelude.

## Deviations from the H98 Prelude (current)

- **Still exported for compatibility:** `ord`, `chr`, `isAscii`,
  `isControl`, `isPrint`, `isSpace`, `isUpper`, `isLower`, `isAlpha`,
  `isDigit`, `isAlphaNum`, `toUpper`, `toLower` (H98: only in `Char`); the
  Dialogue I/O names.
- **Always in scope** (compiler core symbols in `PreludeCore`): the
  types `Ratio`, `Complex` (with `:+`) and `Array`.  Programs cannot
  define these names unless their `import Prelude` hides them (`import
  Prelude hiding ((*))`; `Assoc` and `:=` always may be defined:
  `hidden-core-name?` in `top/symbol-table.mumble`).  The 1.2 `Text`, `Binary` and `Bin` are not
  core names here (`*feature-retired-names*` in
  `top/core-symbols.mumble`).
- Tuples of 2 to 7 components have `Eq` and `Ord` instances in
  PreludeCore.hs, as base has; otherwise the runtime builds
  tuple dictionaries for `Eq`, `Ord`, `Ix`, `Bounded`, `Show` and `Read`; superclass slots are
  computed from the class definitions, and `compare` is the last `Ord`
  method; `Ix`'s methods are range, index, inRange, rangeSize
  (`src/runtime/tuple-prims.mumble`).
- Arrays take H98 `(i, e)` pairs (the 1.2 `i := e` form is gone).
- `Char` is Latin-1; the character predicates follow Latin-1.
- Programs run with the host's float traps masked, so `1/0` is `Infinity`
  and `0/0` is `NaN`, as in H98.
- A unit file (`.hu`) with a `:package` line is a package written against
  GHC's base, ported unchanged (parsec, `Text/Parsec*`): its modules see
  base's Prelude (PreludeModern imported implicitly, Foldable's names and
  MonadFail's `fail`, no `catch`) whatever the dialect mode, where other
  library modules see the Haskell 98 Prelude.  CPP's `MIN_VERSION_pkg`
  answers from the versions in `*cpp-package-versions*`
  (`src/compiler/parser/cpp.mumble`).
