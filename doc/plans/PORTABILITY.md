# Plan: Lisps other than SBCL

Mumble is about 2,700 lines of CL macros and packages
(src/mumble/cl-*.lisp); the compiler is ordinary code on top.  Porting
is mostly a matter of finding the SBCL-specific bits.

## Status (2026-10-09)

| Lisp | Builds | Tests | Startup |
|------|--------|-------|---------|
| SBCL | yes (saved image) | 200 / 200 | instant |
| ECL 26.5 | yes (launcher script) | 193 / 200 | ~0.7 s |
| ABCL 1.9.2 | yes (launcher script) | 162 / 200 | ~20 s |

    make LISP=ecl            # or LISP=abcl; builds build/<lisp>/<dialect>/
    YALE_HASKELL_LISP=ecl bin/yale-haskell --haskell98 prog.hs
    YALE_HASKELL_LISP=ecl tests/run-tests -j 8

### How the build works

- **`tools/build/runtime.lisp`** loads everything the executable holds:
  the compiler, the Prelude, clingon, CFFI and the plain-CL runtimes.
- **`tools/build/image.lisp`** saves that as an image on SBCL.
- **Elsewhere**, image.lisp writes `build/<lisp>/<dialect>/yale-haskell` as a
  shell script. It starts the Lisp on `tools/build/start.lisp`, which loads
  the compiled files from `$Y2` and calls the CLI with the arguments after `--`.
- **Stale builds:** `bin/yale-haskell` refuses to start a non-SBCL build whose
  sources are newer than the build. Otherwise the launcher would recompile
  them, and parallel test runs corrupt the fasls that way.
- **Running the build steps:** the Makefile's `RUN_LISP` runs each step:
  - ECL: `ecl --shell`;
  - ABCL: `java … org.armedbear.lisp.Main`, run directly for `-Xss` and
    through `tools/build/abcl-run.lisp`, so that an error gives exit status 1.

### What changed for portability

- **Feature tests:** `#+(or sbcl ...)` lists in the mumble layer include
  `ecl abcl`. `define-setf-method`/`defconstant` use the ANSI versions.
- **`eval-when` situations** use the ANSI keywords. ABCL ignores the old
  `(eval compile load)` symbols, so local macros were never defined.
- **Host helpers** in cl-definitions.lisp, exported from MUMBLE:
  - `char-general-category`: SBCL and the JVM know Unicode. ECL uses an
    approximation that is exact for ASCII.
  - `host-unicode-case-function` (special cases include µ→Μ).
  - `wrap-signed` (Data.Bits).
  - `rational->float`, which rounds ties to even. ECL rounds 10^23 wrongly.
  - `simple-string-of`: ECL's `namestring` returns non-simple strings.
  - `host-pid`.
- **ECL runtime fixes:**
  - IEEE infinities and NaN come from `ext:`.
  - Float traps are masked through `ext:trap-fpe`.
  - `.fas` fasl type: `.o` collided with ECL's intermediate object file.
- **base-runtime.lisp** uses uiop (processes, directories) and CFFI
  (`getenv`, `setenv`, `mkdir`, `access`) instead of sb-ext/sb-posix. It has
  portable fallbacks when CFFI is unusable (feature `:yale-cffi`).
- **ABCL-specific:**
  - Its own `LISP` package exports all of CL. It can't be renamed, because
    its autoloader uses the name.
  - Mumble's exports are recorded in `build/abcl/src/mumble/mumble-exports.lisp`
    and replayed before loading the fasls.
  - `define-mumble-synonym` resolves autoload stubs before copying them.
  - `define` of a variable expands to `defparameter` + `setq`: ABCL leaves
    defparameter initforms unexpanded.
  - Generated code uses `(safety 1)`: `(safety 0)` produces JVM VerifyErrors
    (Prelude's formatRealFloat, Complex magnitude).
  - `src/cli/abcl-with-user-abort.lisp` stands in for with-user-abort,
    which clingon needs but which does not support ABCL.

## ECL: the 7 failures

1. **deep-recursion, tail-calls, cputime:**
   - The C stack overflows. ECL runs on the main thread, whose stack macOS
     caps at 64 MB (`ulimit -s hard`); SBCL is given 512 MB.
   - Threads did not help: they crashed even at modest depths.
   - On Linux the hard limit is usually unlimited, and the launcher then asks
     for 1 GB.
2. **show-integral:** fixnums are 62-bit, so `minBound :: Int` differs.
   - Make the test host-independent, or accept per-host output.
3. **directory:** the `#-sbcl` branches of src/runtime/system-prims.mumble are
   weak. Unix-style errors are missing, the listing is wrong and renaming a
   directory fails.
   - Replace those branches with CFFI calls (mkdir, rmdir, unlink, rename,
     opendir, getcwd, chdir, access, chmod, stat) in a plain-CL file loaded
     after CFFI, as base-runtime.lisp does.
   - `stat`'s struct layout is per platform (darwin vs. linux).
   - errno → IOError kinds can use hard-coded numbers; they agree on darwin
     and linux except EDQUOT.
   - Doing this for SBCL too would remove the sb-posix code.
4. **marshalling (FFI):** a segfault in a CFFI call on ECL after the first
   result. Investigate in src/ffi/ffi-runtime.lisp.
5. **repl/session:** `import NoSuchModule` at the prompt prints nothing
   instead of the "Cannot find module" error. Some condition is presumably
   handled differently there.

## ABCL: future work (38 failures)

Left for later.  What was seen:

- **Int is 32-bit** (ABCL fixnums), so Data.Int's Int32/Word32 over Int
  overflow at compile time.
  - Generate Data.Int/Data.Word per host width (tools/gen/gen-intword.py),
    or put the 32-bit types over Integer.
- **Runtime errors and other diagnostics go to stdout,** not stderr: about
  15 of the failures (runtime-error, pattern-match-failure, records-*,
  modules/* error tests).
  - Check how `*error-output*` / `*error-output-port*` reach the JVM's
    System.err in start.lisp.
- **There is no FFI:** CFFI needs JNA, which is not installed (abcl-contrib
  can fetch it through Maven).
- **Unicode:** check unicode-chars and unicode-source against the Java
  tables.
- **Floats:** float-ieee and numeric-misc fail. ABCL does not trap, but
  `float-nan-like` etc. need checking.
- **Stack depth:** deep-recursion, deep-stack and tail-calls fail. The
  launcher passes `-Xss512m`, but ABCL does not eliminate tail calls.
- **Startup takes ~20 s.** Most of it is loading fasls. An ABCL jar of the
  system, or ASDF's `program-op`, might help.
- **The remaining failures** (system/*, cputime, random, blackhole-loop)
  have not been examined.

## The unit cache on ECL and ABCL

Compiled units are cached between runs (src/compiler/csys/unit-cache.mumble).
This is tested on SBCL only.
- Cached units are written with `compile-file`. On ECL that runs the C
  compiler for each unit, so a cold run is slow; later runs load the
  `.fas` files.
- The in-core path (`load-code-in-core` in compiler-driver.mumble) goes
  through a temporary file only on SBCL. There `eval` of a whole program
  is about 14 times slower than `compile-file`; other Lisps still use `eval`.
- Check `rename-file-replacing` (cl-definitions.lisp) on each Lisp: the
  cache relies on renaming over an existing file.

## Next steps

1. **CFFI-based POSIX layer** for the `#-sbcl` system primitives (ECL item 3).
2. **Make the Int width a host constant** everywhere
   (`most-positive-fixnum`). Data.Bits already does this; Data.Int/Data.Word
   and the tests remain.
3. **CCL**, as a third Lisp.
4. **ASDF `program-op` build** (doc/ASDF-PORTING.md). On ECL it could
   produce a real executable instead of the launcher.
5. **CI on each Lisp.**
