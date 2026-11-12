# YHS-0.1a: Linux CI failures after YHS-0.1

Status: review (one failure still open)

CI run 43167422525 (commit a0479ce):

- macOS: `make deps` failed: ocicl lost its connection to ghcr.io while
  fetching `global-vars` and `with-user-abort`. Every test then exited 127.
- Ubuntu: built, and 916 of 925 tests passed.

| Failure | Cause | Fix |
|---|---|---|
| macOS `make deps` | dropped ghcr.io connection | `make deps` retried twice |
| `ffi/foreign-2010` | no `src/ffi/errno-linux.lisp`: every errno constant was -1 | added the table, loaded on `:linux` in `yale-haskell.asd` (`tools/build/runtime.lisp` loads it by `software-type`) |
| `liquid/*`, 7 tests | runners have no z3 | `apt-get install z3`, `brew install z3` |
| `system/stack-overflow` | `Unhandled memory fault` in the `yale-haskell` thread (512 MB stack) instead of `control-stack-exhausted` | **open** |

`errno-linux.lisp` was written by hand, not by `tools/gen/gen-errno.sh`, since
no Linux machine was available. Its values come from Linux's
`include/uapi/asm-generic/errno-base.h` and `errno.h`, which x86-64 and aarch64
share. Regenerate it with the script on Linux.

Verification on macOS:

- `yale-haskell.asd` reads.
- The Linux table loads and has 94 entries.
- `tests/run-tests tests/haskell98/ffi/foreign-2010.hs` passes.
- `ci.yml` parses as YAML.

The Linux results come only from CI, after the human pushes `ng`.

Open: `stack-overflow` on Linux. The fault address is sp-8, just below a page
boundary, which looks like a stack guard-page hit, but SBCL does not recognise
it as this thread's guard page. Investigating it needs a Linux x86-64 machine,
or a CI step that runs the test with `YALE_HASKELL_STACK_MB` set lower.
