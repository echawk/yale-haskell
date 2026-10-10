# Yale Haskell

Yale Haskell is a Haskell compiler written at Yale in the early 1990s by
the Yale Haskell Group.  This is Y2.0.5 (1994), which implements
**Haskell 1.2**, revived to build on a modern Common Lisp.  The long-term
goal is Haskell 98; see [doc/REVIVAL-PLAN.md](doc/REVIVAL-PLAN.md).

The compiler is written in [*mumble*](src/mumble/README.md), a small
Scheme-flavoured Lisp dialect implemented on top of Common Lisp; despite
appearances it is **not** Scheme.
Haskell programs are compiled to Lisp and then to native code by the
host Lisp compiler.

## Building

You need [SBCL](https://www.sbcl.org) (tested with 2.6), `make`, and
[ocicl](https://github.com/ocicl/ocicl) for the Lisp libraries the
command line uses (clingon; cl-unicode for upcoming Unicode support),
pinned in `ocicl.csv`.

```sh
make deps       # ocicl install: fetch the Lisp libraries into ocicl/
make            # compiler, prelude, and the build/sbcl/yale-haskell executable
make test       # run the test suite
make clean      # remove build/
```

Build logs are written to `build/sbcl/logs/`.

## Running

```sh
bin/yale-haskell examples/demo/queens.hs        # compile a program and run Main.main
bin/yale-haskell --haskell98 prog.hs a b        # Haskell 98; a b are getArgs
bin/yale-haskell --haskell98                    # the interactive system
bin/yale-haskell --haskell98 repl prog.hs       # ... with prog.hs loaded
bin/yale-haskell --haskell98 -e 'sum [1..100]'  # evaluate and exit
bin/yale-haskell --help                         # options: --backend, --printers, ...
bin/yale-haskell --haskell98 compile prog.hs --emit lisp -o prog.lisp   # compile only
```

Files with `{-# LANGUAGE CPP #-}` go through a built-in C preprocessor
(`#include`, `#define`, `#if`); `--cpp` applies it to every file, and
`-D NAME[=VALUE]` and `-I DIR` work as for cpp.

`compile FILE --emit STAGES` writes compiler stages for the program's own
modules instead of running it, to `-o FILE` or stdout.  STAGES is a
comma-separated list:
- the passes `scope`, `depend`, `cfn`, `flic`, `optimize`,
  `strictness`, `grin` and `codegen`, as `--printers` shows them;
- `lisp`, the whole generated Lisp file;
- `asm`, SBCL's disassembly of each top-level function.

To see what the optimizations do, combine it with `--optimizers` (FLIC:
`foldr,inline,constant,lisp`), `--grin-optimizations` (`-g`) and
`--backend`. Each list takes names, `+name`, `-name`, `all` or `none`.

The interactive system works like GHCi: type an expression to evaluate
it (an `IO` action is run), a definition (`x = ...`, `f x = ...`,
`data ...`, `let ...`) to keep it, or `import M`; commands include
`:type`, `:load`, `:reload`, `:browse`, `:info`, `:module`, `:set +t`,
`:set +s`, `:{ ... :}` and `:quit`, plus Yale Haskell's own `:grin`,
`:lisp`, `:flic` and `:asm` (show an expression's intermediate or generated
code), `:set backend`, `:set printers` and `:profile`.  `:?` lists
them.  With `rlwrap` installed it has line editing and history.  The
full guide, including current limitations, is [doc/REPL.md](doc/REPL.md).

Compiled modules are cached in `~/.cache/yale-haskell/` (or
`$YALE_HASKELL_CACHE_DIR`), so a program compiles once and later runs
reuse it until its sources change; the interactive system caches only
library modules.  `YALE_HASKELL_CACHE=0` turns the cache off and
`YALE_HASKELL_CACHE=library` limits it to library modules.  A new build
starts a new cache; old ones can be deleted.  See
`src/compiler/csys/unit-cache.mumble`.

Programs use Haskell 1.2 conventions: `main` is a `Dialogue`, e.g.

```haskell
main = appendChan stdout "Hello, world!\n" abort done
```

## Layout

| Path | Contents |
|---|---|
| `src/mumble/` | the mumble dialect (Common Lisp implementation) and its compilation-unit system — [what is mumble?](src/mumble/README.md) |
| `src/compiler/` | the compiler phases (`parser/`, `type/`, `backend/`, …), the interactive top level (`command-interface/`), and `system.mumble`, which loads them all |
| `src/runtime/` | runtime primitives used by compiled Haskell code |
| `lib/haskell-1.2/` | the Haskell 1.2 Prelude and libraries |
| `examples/` | the tutorial and demo programs (Haskell 1.2) |
| `tools/build/` | Lisp drivers used by the Makefile |
| `tools/emacs/` | the original Emacs interface |
| `tests/` | test suite (`make test`) |
| `doc/` | documentation; [doc/REVIVAL-PLAN.md](doc/REVIVAL-PLAN.md) is the modernisation plan, `doc/history/` the 1994 README |
| `ref/` | untracked reference clones (Hugs, the H98 Report); `make ref` |
| `build/` | all build output |

## License

See [Copyright](Copyright): free to copy and use with attribution to the
Yale University Computer Science Department.
