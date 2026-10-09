# Tests

Run everything with `make test`, or a subset with
`tests/run-tests [-v] [-j N] tests/haskell98/prelude`.

| Option | Effect |
|---|---|
| `-v` | list every test; show the diff and stderr of failures |
| `-t SECONDS` | per-test time limit (default 120) |
| `-j N` | run N tests at once (default 1); results are still printed in order |

## Layout and conventions

```
tests/<dialect>/<area>/<name>.hs        the program (module Main, defines main)
tests/<dialect>/<area>/<name>.stdout    expected stdout, byte for byte
tests/<dialect>/<area>/<name>.exit      expected exit status (optional; default 0)
tests/<dialect>/<area>/<name>.stdin     stdin for the program (optional)
tests/<dialect>/<area>/<name>.xfail     marks an expected failure; first line = reason
tests/<dialect>/<area>/<name>.repl      an interactive session instead of a program:
                                        typed at `yale-haskell repl`; stdout (minus the
                                        banner line) is compared with <name>.stdout
```

- `<dialect>` is `haskell-1.2` or `haskell98`; the test is run with
  `bin/yale-haskell --<dialect>`.  `<area>` is free-form (`smoke`,
  `prelude`, `lib`, `language`, `demo`, …).
- A test passes when the program's exit status is the expected one (0
  unless there is a `.exit` file) and its stdout matches `.stdout`
  exactly.  Compile errors and runtime errors give status 1.
- **Tests that must fail.**  A `.exit` file holds the expected exit
  status on its first line, e.g. `1` for a program that must be
  rejected by the compiler or must stop with a runtime error.  The
  `.stdout` is still compared if it exists; compiler diagnostics go to
  stderr, so for a compile error it is empty.  A
  runtime-error test can keep a `.stdout` with the output produced
  before the error.
- **Compiler options.**  A `.flags` file holds options for
  `bin/yale-haskell` on its first line, e.g. `--haskell2010`.
- `.hs` files with neither `.stdout` nor `.exit` are not tests (e.g.
  helper modules).
- **Multi-module tests.**  Yale Haskell finds modules through *unit
  files* (`.hu`: one file name per line, `.hs` sources or other `.hu`
  units).  If `<name>.hu` exists next to `<name>.hs`, the compiler uses
  it automatically, so a test that imports a library lists the
  library's unit, e.g. `$HASKELL_LIBRARY/List.hu`.  Helper modules
  live next to the test; see `haskell-1.2/demo/calendar-main.hu`.
- **Expected failures.**  A test for something not implemented yet
  gets a `.xfail` file whose first line says what is missing, e.g.
  `needs do-notation (M4)`.  It is reported as `xfail` while it fails,
  and as `XPASS` — which fails the run — once it passes, so the marker
  gets removed when the feature lands.
- Write the expected output from the Haskell 98 Report's semantics (or
  by running the program in a reference implementation such as GHC),
  not by copying whatever Yale Haskell prints today.
- Programs that run in parallel (`-j`) share the compiled-library
  directories under `build/`; if two tests compile the same library at
  the same time, run with `-j 1`.

`haskell-1.2` tests describe the original system and must keep passing.
`haskell98` tests describe the target language; most will start out as
expected failures.

## Areas

- `haskell-1.2/smoke`, `haskell98/smoke`: one quick program each.
- `haskell-1.2/demo`: the programs in `examples/demo` (not X11), with
  input and the recorded output.
- `haskell98/language`: one H98 language feature per test.  Output goes
  through Dialogue I/O (`main = appendChan stdout s abort done`) until
  `IO` and `do` exist (M4), so most tests exercise their feature in pure
  code.  Each `.xfail` names the milestone in doc/REVIVAL-PLAN.md that
  should make it pass.  Lexical and syntax items are in
  `haskell98/syntax`.
