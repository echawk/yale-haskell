# Yale Haskell

Yale Haskell is a Haskell compiler written at Yale in the early 1990s by
the Yale Haskell Group.  Its last release, Y2.0.5 (1994), implemented
**Haskell 1.2**; this is its revival on a modern Common Lisp, version
**3.1.0.0**, which compiles Haskell 98 and Haskell 2010 with a large set
of GHC extensions and the commonly used libraries (CHANGELOG.md lists
the versions; doc/REVIVAL-PLAN.md the history).  Hackage packages build
with MicroCabal's Yale backend (doc/PACKAGES.md): about 80, the
dependencies of Agda among them, and Agda itself is the current target
(doc/plans/MICROCABAL.md).

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

`--ghc2021` and `--ghc2024` compile in GHC's languages of those names:
their extensions are on in every module, with GHC base's Prelude
(`--modern-prelude`); `-X NAME` (or `-XNAME`) turns on one more
extension, `-X NoNAME` turns one off, as for GHC.  A
`{-# LANGUAGE GHC2021 #-}` pragma, or a package's `default-language`,
does the same for one module.

Files with `{-# LANGUAGE CPP #-}` go through a built-in C preprocessor
(`#include`, `#define`, `#if`); `--cpp` applies it to every file, and
`-D NAME[=VALUE]` and `-I DIR` work as for cpp.

`build FILE [-o EXE]` makes a standalone executable, as `ghc FILE`
does: the image with the program compiled and loaded, which runs
`Main.main` with every argument its own (`--help` included) and needs
neither the source tree nor the environment.  Executables are large
(about 65 MB: the whole Lisp image) and start in about 0.05 s.

```sh
bin/yale-haskell --haskell98 build prog.hs -o prog && ./prog a b
```

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
starts a new cache and removes those of the same checkout's older
builds.  See
`src/compiler/csys/unit-cache.mumble`.

Modules are looked for next to the importing file, then in the `-i DIR`
directories (and `$YALE_HASKELL_PATH`, colon-separated), then in
installed packages: `--package-db DIR` (or `$YALE_HASKELL_PACKAGE_DB`)
names a directory of packages, each `NAME-VERSION/` with its modules in
`src/`, its include files in `include/`, and a `yale-package` file of
`name:`, `version:`, `extensions:`, `cpp-options:` and `include-dirs:`
lines that apply to its own modules (MicroCabal's Yale backend,
`tools/microcabal/`, writes them).

Programs run with a 512 MB control stack, used only as far as they
recurse; `YALE_HASKELL_STACK_MB` sets another size.  A program that
runs out of stack prints `stack overflow` and exits with status 2, as
GHC's does.

Without a language flag the compiler reads Haskell 1.2, where `main` is
a `Dialogue`, e.g.

```haskell
main = appendChan stdout "Hello, world!\n" abort done
```

`--haskell98` selects Haskell 98 (and 2010); `--modern-prelude` (implied
by `--ghc2021` and `--ghc2024`) gives modules GHC base's Prelude.

## Layout

| Path | Contents |
|---|---|
| `src/mumble/` | the mumble dialect (Common Lisp implementation) and its compilation-unit system — [what is mumble?](src/mumble/README.md) |
| `src/compiler/` | the compiler phases (`parser/`, `type/`, `backend/`, …), the interactive top level (`command-interface/`), and `system.mumble`, which loads them all |
| `src/runtime/` | runtime primitives used by compiled Haskell code |
| `src/base/` | the Lisp runtime of the Haskell 98 libraries (text, bytestring, I/O, POSIX, parallelism) |
| `src/ffi/` | the C foreign function interface (doc/FFI.md) |
| `src/cli/` | the command line (`bin/yale-haskell`) |
| `src/liquid/` | refinement types (doc/plans/LIQUID-HASKELL.md) |
| `lib/haskell-1.2/` | the Haskell 1.2 Prelude and libraries |
| `lib/haskell98/` | the Haskell 98 and 2010 Prelude and libraries, and base, containers, text, mtl ... under their GHC module names |
| `examples/` | the tutorial and demo programs (Haskell 1.2) |
| `tools/build/` | Lisp drivers used by the Makefile |
| `tools/microcabal/` | MicroCabal's Yale backend and the package patches (doc/PACKAGES.md) |
| `tools/conformance/` | conformance runners: extension probes, nofib, real programs |
| `tools/emacs/` | the original Emacs interface |
| `tests/` | test suite (`make test`) |
| `doc/` | documentation; [doc/REVIVAL-PLAN.md](doc/REVIVAL-PLAN.md) is the modernisation history, [doc/plans/](doc/plans/README.md) the current plans, `doc/history/` the 1994 README |
| `bench/` | benchmarks against GHC ([bench/RESULTS.md](bench/RESULTS.md)) |
| `ref/` | untracked reference clones (Hugs, the H98 Report); `make ref` |
| `build/` | all build output |

## License

See [Copyright](Copyright): free to copy and use with attribution to the
Yale University Computer Science Department.
