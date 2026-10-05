# Tests

Run everything with `make test`, or a subset with
`tests/run-tests [-v] tests/haskell98/prelude`.

## Layout and conventions

```
tests/<dialect>/<area>/<name>.hs        the program (module Main, defines main)
tests/<dialect>/<area>/<name>.stdout    expected stdout, byte for byte (required)
tests/<dialect>/<area>/<name>.stdin     stdin for the program (optional)
tests/<dialect>/<area>/<name>.xfail     marks an expected failure; first line = reason
```

- `<dialect>` is `haskell-1.2` or `haskell98`; the test is run with
  `bin/yale-haskell --<dialect>`.  `<area>` is free-form (`smoke`,
  `prelude`, `lib`, `language`, `demo`, …).
- A test passes when the program exits with status 0 and its stdout
  matches `.stdout` exactly.  Compile errors and runtime errors give
  status 1.
- `.hs` files without a `.stdout` are not tests (e.g. helper modules).
- **Multi-module tests.**  Yale Haskell finds modules through *unit
  files* (`.hu`: one file name per line, `.hs` sources or other `.hu`
  units).  If `<name>.hu` exists next to `<name>.hs`, the compiler uses
  it automatically, so a test that imports a library lists the
  library's unit, e.g. `$HASKELL_LIBRARY/List.hu`.
- **Expected failures.**  A test for something not implemented yet
  gets a `.xfail` file whose first line says what is missing, e.g.
  `needs do-notation (M4)`.  It is reported as `xfail` while it fails,
  and as `XPASS` — which fails the run — once it passes, so the marker
  gets removed when the feature lands.
- Write the expected output from the Haskell 98 Report's semantics (or
  by running the program in a reference implementation), not by
  copying whatever Yale Haskell prints today.
- Each test has a 120-second limit (`-t` to change).

`haskell-1.2` tests describe the original system and must keep passing.
`haskell98` tests describe the target language; most will start out as
expected failures.
