# The interactive system

`bin/yale-haskell` without a program file starts the interactive system,
a read-eval-print loop modelled on GHCi.  The implementation is
`src/compiler/command-interface/repl.mumble` (the loop and commands) and
`src/cli/cli.lisp` (the command line); see REVIVAL-PLAN.md, M10.

```sh
bin/yale-haskell --haskell98                    # start with an empty Main
bin/yale-haskell --haskell98 repl prog.hs       # load files first
bin/yale-haskell --haskell98 -e 'sum [1..100]'  # evaluate and exit (repeatable -e)
bin/yale-haskell --haskell98 -e 'f 3' prog.hs   # ... with prog.hs loaded
```

The dialect (`--haskell98`, `--haskell1.2`, or `$YALE_HASKELL_DIALECT`)
is fixed for the session.  `yale-haskell --help` lists the options:
`--backend grin|flic`, `--printers P,...`, `--no-optimize`,
`--grin-optimizations O,...`, `--foreign-library LIB` (`-l`, repeatable;
see FFI.md), `--version`.

With `rlwrap` installed and a terminal, input has line editing and a
history in `~/.yale_haskell_history`; `YALE_HASKELL_RLWRAP=no` turns it
off.  `~/.yhaskell` (Lisp) is loaded at start-up if it exists.

## Input

| You type | What happens |
|---|---|
| an expression | it is evaluated.  An `IO` action (a `Dialogue` in Haskell 1.2) is run, and its result printed unless it is `()` or has no `Show` instance; any other value is printed with `print`, so its type needs `Show` |
| a definition | `x = ...`, `f x = ...`, `data`/`type`/`newtype`/`class`/`instance`/`infix`, or `let ...` without `in`: it is compiled and kept for later input.  Entering a name again replaces the earlier definition |
| `import M` | adds an import (see limitations) |
| `:{` ... `:}` | a multi-line input (an expression or definitions) |
| `:command` | see below |

How input is classified: a line is a definition if it starts with a
declaration keyword, with `let` but has no `in`, or has an `=` outside
brackets that is not part of an operator (`==`, `<=`, ...).  Everything
else is an expression.

Input is compiled as an extension of the current module, so it sees all
of that module's top-level names, exported or not (like GHCi's `*M`).

## Commands

Any unique prefix works, as in GHCi: `:t`, `:l`, `:r`, `:q`, `:b`, `:i`, `:m`.

| Command | |
|---|---|
| `:?`, `:help` | list the commands |
| `:quit` | leave (end of input does too) |
| `:type EXPR` | the type of an expression.  The monomorphism restriction is off here, as in GHCi, so `:t 1 + 2` is `Num a => a` |
| `:load FILE ...` | load modules; the prompt works in `Main` if loaded, else the first module.  `:load` alone returns to the scratch module |
| `:reload` | load the same files again |
| `:browse [M]` | a module's exported names with their types |
| `:info NAME` | what a name is, its type, and its module |
| `:module [M]` | work in another loaded module; `:module` alone returns to the scratch module |
| `:set` | show the settings |
| `:set +t` / `:unset +t` | print the type of each result and definition |
| `:set +s` / `:unset +s` | print time and bytes allocated after each evaluation |
| `:cd DIR` | change directory |
| `:!CMD` | run a shell command |

## Yale Haskell's own commands

| Command | |
|---|---|
| `:grin EXPR` | the GRIN intermediate code (LGRIN, doc/EVAL-APPLY-GRIN.md) for an expression |
| `:lisp EXPR` | the Common Lisp generated for it |
| `:flic EXPR` | the optimised FLIC code (the `optimize` printer) |
| `:set backend grin` / `flic` | the code generator for what is compiled next |
| `:set printers P ...` | print these compiler passes for everything compiled (`:set printers` alone turns them off); the pass names are those of `--printers` and `*all-printers*` (`parse`, `type`, `flic`, `optimize`, `strictness`, `grin`, `codegen`, `phase-time`, ...) |
| `:set grin O ...` | the GRIN optimizations (`fold speculate inline-eval self-local rep-types ftype`): names alone set exactly those, `+o`/`-o` add or remove one, `all`/`none`; `:unset grin O` removes; `:set grin` shows them.  On the command line, `-g`/`--grin-optimizations` with the same words comma-separated |
| `:set optimizers O ...` | the FLIC optimizer passes (`foldr inline constant lisp`); `:set noopt` turns them off, `:unset noopt` on |
| `:profile EXPR` | evaluate under SBCL's statistical profiler and print the top of a flat report (`make profile FILE=...` does this for a whole program) |

## Errors

Compile errors are reported in the compiler's own format
(`[ID] Phase error in phase TYPE: ...`), runtime errors as
`Haskell runtime abort.` followed by the message, and Lisp errors as
`*** Exception: ...`.  After any of them, and after `^C`, you are back at
the prompt with your definitions intact.

## Limitations (to do)

- `import` at the prompt works in the scratch module (no file loaded).
  With a file loaded it asks you to add the import to the file and
  `:reload`.
- `it` is not kept between inputs.
- A prompt definition cannot redefine a name of the loaded module itself
  (only earlier prompt definitions).
- `:info` does not yet show class members or instances.
- Error messages are the compiler's, wordier than GHCi's.
- The executable is still built by `tools/build/image.lisp`; an ASDF
  `program-op` build is planned (REVIVAL-PLAN.md, M10).
- The 1993 command interface (`heval`, extensions and `:eval`) is still
  in the image but no longer reachable from the command line.
