# cubicaltt support files

Used by `tools/conformance/cubicaltt.py` (see doc/plans/CUBICALTT.md).

- `Exp/`: the parser of cubicaltt's grammar (`Exp.cf`, from
  https://github.com/mortberg/cubicaltt at 9baa6f2, MIT licence),
  generated with BNFC 2.9.6.3, Alex and Happy 2.0:
  `bnfc --haskell -d Exp.cf && alex Exp/Lex.x && happy Exp/Par.y`.
  Committed so that running the test needs none of those tools.
- `include/`: empty stand-ins for GHC's `MachDeps.h` and `ghcconfig.h`,
  which the Alex and Happy output `#include`s.
- `expected/`: GHC 9.14's output for each example (`cubical -b NAME.ctt`
  run in the examples directory), and GHC's time for each
  (`ghc-times.txt`, `-O`, one at a time).
