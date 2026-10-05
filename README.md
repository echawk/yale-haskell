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

You need [SBCL](https://www.sbcl.org) (tested with 2.6) and `make`.

```sh
make            # compiler, prelude, and the build/sbcl/yale-haskell executable
make test       # run the test suite
make clean      # remove build/
```

Build logs are written to `build/sbcl/logs/`.

## Running

```sh
bin/yale-haskell examples/demo/queens.hs   # compile a program and run Main.main
bin/yale-haskell                        # interactive command interface (:? for help)
```

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
