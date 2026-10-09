# Haskell 98 libraries (work in progress)

This tree is the Haskell 98 counterpart of `lib/haskell-1.2/`.  It is
built as a separate *dialect*: `make` compiles both Preludes and saves
one executable per dialect, and `bin/yale-haskell --haskell98` selects
this one.

| Path | Contents |
|---|---|
| `prelude/` | the Prelude.  It started as a copy of the 1.2 Prelude and is being moved towards the H98 Report's Standard Prelude as the compiler gains the language features it needs. |
| `<Module>.hs`, `<Module>.hu` | the H98 standard libraries: `List`, `Char`, `Maybe`, `Numeric`, `Ratio`, `Complex`, `Ix`, `Array`, `IO`, `System`, `Directory`, `Time`, `Locale`, `CPUTime`, `Random`, `Monad`; and `Dialogue` (Yale: Haskell 1.2 stream I/O, `appendChan stdout ... abort done`) |

Reference material: the Report (`ref/haskell-report`, branch `h98`) is
the specification; Hugs (`ref/hugs98`, `libraries/hugsbase/Hugs/Prelude.hs`
and `packages/haskell98`) is the reference implementation.  See
`ref/README.md` for licensing when borrowing code.

The compiler still implements Haskell 1.2 (no constructor classes,
`do`, `newtype`, records or qualified names; see
`doc/REVIVAL-PLAN.md` §3).  Anything here must compile with the
compiler as it is today; definitions that need a missing feature are
left out until that feature lands, and the tests that need them are
marked as expected failures (`tests/README.md`).

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
  define these names.  (`Assoc` and `:=` are core symbols too, but user
  modules may define them: `hidden-core-name?` in
  `top/symbol-table.mumble`.)  The 1.2 `Text`, `Binary` and `Bin` are not
  core names here (`*feature-retired-names*` in
  `top/core-symbols.mumble`).
- The runtime builds
  tuple dictionaries for `Eq`, `Ord`, `Ix`, `Bounded`, `Show` and `Read`; superclass slots are
  computed from the class definitions, and `compare` is the last `Ord`
  method; `Ix`'s methods are range, index, inRange, rangeSize
  (`src/runtime/tuple-prims.mumble`).
- Arrays take H98 `(i, e)` pairs (the 1.2 `i := e` form is gone).
- `Char` is Latin-1; the character predicates follow Latin-1.
- Programs run with the host's float traps masked, so `1/0` is `Infinity`
  and `0/0` is `NaN`, as in H98.
