# mumble

The Yale Haskell compiler is written in **mumble**, a small Lisp dialect
that the Yale Haskell Group designed so that one code base could run on
both T (a Scheme) and Common Lisp.  It looks like Scheme (`define`,
`#t`/`#f`, `lambda` with dotted argument lists), but it is **not
Scheme**:

- there are no first-class continuations, and tail calls are only as
  good as the host Lisp's;
- functions and variables share one namespace (like Scheme), but
  global functions are referenced with `(function f)` and called via
  `funcall` when bound locally;
- it adds Common Lisp facilities: `setf`, `dynamic-let`, structures
  (`define-struct`), multiple values, `typecase`, declarations;
- `define-syntax` is a non-hygienic, `defmacro`-style macro.

Today the only implementation is the Common Lisp one in this directory;
the T implementation was dropped before this release.  Source files use
the `.mumble` extension (they were `.scm` in the original release).

## Files

| File | Purpose |
|---|---|
| `cl-setup.lisp` | creates the `MUMBLE` and `MUMBLE-IMPLEMENTATION` packages |
| `cl-support.lisp` | macros for defining mumble primitives in terms of CL |
| `cl-definitions.lisp` | the dialect itself: special forms, data types, I/O, files |
| `cl-types.lisp` | type names and `typecase` |
| `cl-structs.lisp` | `define-struct`, the structure system used for the AST |
| `cl-init.lisp` | entry point: compiles/loads the files above, then the compiler |
| `wcl-patches.lisp` | patches for WCL (unsupported) |
| `support.mumble` | compilation unit for the shared utilities below |
| `compile.mumble` | the *compilation unit* system (a make-like dependency loader used by every `*/<dir>.mumble` unit file) |
| `utils.mumble`, `format.mumble`, `pprint.mumble` | general utilities, `format`, an XP pretty printer |
| `mumble-reference.txt` | **the language reference** — every special form and primitive |
| `PORTING` | notes on porting to another Common Lisp (the build-script steps are obsolete; see the top-level `Makefile`) |

Mumble code is read in the `MUMBLE-USER` package, which uses only
`MUMBLE`; Common Lisp symbols must be written `lisp:foo`.

## Host Lisps

The CL implementation is conditionalised with `#+sbcl`, `#+cmu`, … in
these files only (never in compiler sources).  SBCL is the supported
host.  The older branches (Lucid, Allegro, LispWorks, AKCL, CMU CL,
MCL, WCL) are retained for reference but untested; ECL and ABCL are
candidate second hosts.

## Editor support

Emacs has no mumble mode; `scheme-mode` indents it well:

```elisp
(add-to-list 'auto-mode-alist '("\\.mumble\\'" . scheme-mode))
```
