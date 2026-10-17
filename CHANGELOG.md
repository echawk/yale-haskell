# Changelog

Yale Haskell follows [semantic versioning](https://semver.org/):

- **major**: a change that breaks programs or interfaces that compiled
  before (a removed flag, a library or Prelude change that is not
  compatible, a changed compiled-unit format users rely on);
- **minor**: a new feature, extension, library, optimization or flag,
  compatible with what came before;
- **patch**: a bug fix or conformance fix with no new feature.

**4.0.0 is reserved** for the release in which no mumble code is left
(doc/plans/MUMBLE-TO-CL.md).  Until then the major version stays 3: a
change that would otherwise be major goes out as a minor version, marked
**breaking** in its entry here.

The version is `*haskell-compiler-version*` in
`src/compiler/top/globals.mumble` and `:version` in `yale-haskell.asd`;
both change together, with an entry here.  The version is part of every
compiled interface, so a new version recompiles cached units.

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
