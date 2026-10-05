# Yale Haskell

Yale Haskell is a Haskell compiler written at Yale in the early 1990s by
the Yale Haskell Group.  This is Y2.0.5 (1994), which implements
**Haskell 1.2**, revived to build on a modern Common Lisp.  The long-term
goal is Haskell 98; see [docs/REVIVAL-PLAN.md](docs/REVIVAL-PLAN.md).

The compiler is written in *mumble*, a small Scheme-flavoured dialect
implemented as macros on top of Common Lisp; it is **not** Scheme.
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
bin/yale-haskell progs/demo/queens.hs   # compile a program and run Main.main
bin/yale-haskell                        # interactive command interface (:? for help)
```

Programs use Haskell 1.2 conventions: `main` is a `Dialogue`, e.g.

```haskell
main = appendChan stdout "Hello, world!\n" abort done
```

## Layout

| Path | Contents |
|---|---|
| `cl-support/`, `support/` | the mumble dialect and its compilation-unit system |
| `parser/` … `backend/`, `top/`, `csys/` | the compiler phases |
| `runtime/` | runtime primitives |
| `command-interface/` | the interactive top level |
| `progs/prelude/` | the (Haskell 1.2) Prelude |
| `progs/lib/`, `progs/demo/`, `progs/tutorial/` | libraries and example programs |
| `tools/build/` | Lisp drivers used by the Makefile |
| `ref/` | untracked reference clones (Hugs, the H98 Report); `make ref` |
| `doc/` | original documentation (`doc/history/README-1994` is the 1994 README) |

## License

See [Copyright](Copyright): free to copy and use with attribution to the
Yale University Computer Science Department.
