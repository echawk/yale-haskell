# Haskell in Lisp files: `#@hs{ ... }#`

A Common Lisp program can contain Haskell, compiled by Yale Haskell in
the same image, in `#@hs{ ... }#` blocks.  The syntax is that of
[cl-sml](https://github.com/echawk/cl-sml)'s `#@sml{ ... }#` (as of
commit 891d4f6), and the two can be used in one file.

```lisp
#@hs{ import qualified Data.Map as M }#

#@hs{
  fib :: Int -> Int
  fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
}#

(+ 1 #@hs{ 2 * 3 }#)                              ; => 7
(defun fib-of (n) #@hs{ fib ($n :: Int) }#)       ; $n is the Lisp variable N
(defun adder (k) #@hs{ \x -> x + ($k :: Int) }#)  ; (funcall (adder 10) 32) => 42
#@hs{ map (\x -> x * x) $(list 1 2 3) }#          ; => (1 4 9)
#@hs{ M.toList (M.fromList (zip "abc" [1 :: Int ..])) }#
                                                  ; => ((#\a 1) (#\b 2) (#\c 3))
```

`tests/embed/basic.lisp` has an example of each feature.  `make
embed-test` runs it, loading it both as source and as a compiled FASL.

## Loading Yale Haskell into a Lisp

Build Yale Haskell first (`make deps && make`; see README.md).  Then,
in SBCL, register the source tree and its libraries with ASDF, and load
`yale-haskell/runtime`:

```lisp
(require :asdf)
(asdf:initialize-source-registry
 '(:source-registry (:directory "/path/to/yale-haskell/")
                    (:tree "/path/to/yale-haskell/ocicl/")
                    :inherit-configuration))
(asdf:load-system :yale-haskell/runtime)
```

This loads the compiler, the Haskell 98 Prelude and the runtime of the
libraries (FFI, exceptions, `Text`, threads) from the build, about a
second.  `:yale-haskell` alone is the compiler and the Prelude without
that runtime: enough for Haskell 98, not for most packages.

Start SBCL with a larger control stack than the default 2 MB when
Haskell code recurses deeply (`sbcl --control-stack-size 64`; the
`yale-haskell` executable gives its programs 512 MB), and with an 8 GB
heap when it compiles large packages (`--dynamic-space-size 8192`, as
the executable has: aeson's modules exhaust 4 GB).

Then turn the syntax on, for the rest of a file:

```lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (yale-haskell:enable-haskell-syntax (copy-readtable))))
```

`enable-haskell-syntax` keeps the readtable's earlier `#@` reader (for
example cl-sml's) for blocks of other languages.  `#@haskell{ ... }#`
is the same as `#@hs{ ... }#`.

## Blocks

- A block of **imports** (lines starting with `import`) adds them to
  the Haskell module of the current Lisp package.  The module starts
  out importing the Prelude.
- A block of **definitions** (type signatures, functions, `data`,
  `class`, `instance` ...) adds them to that module, for the blocks
  after it.  Defining a name again replaces the earlier definition, as
  at the REPL (doc/REPL.md).
- An **expression** block is a Lisp expression whose value is the
  Haskell value's, converted (below).  An expression of type `IO a` is
  run, and its result is the value.

A block may start with imports and go on with definitions or an
expression.  Each Lisp package has its own Haskell module
(`Lisp_CL_USER` for `CL-USER`), so packages do not see each other's
definitions.  Blocks are dedented, so their declarations may be
indented like the Lisp around them.

`}#` and `$` inside Haskell strings, character literals and comments
are Haskell's.

## Splices

`$name` and `$(form)` splice the values of Lisp forms into an
expression, evaluated where the block is, in its lexical environment,
each time it runs.  `$name` takes letters, digits and `-_*%!?`
(`$*shape*` works); write `$(x)` for other names.

A `$` written right after an operator character (`<$>`, `$!`), or
followed by a space (`f $ x`), is Haskell's.  Write Haskell's `$`
with a space after it: `f $(g x)` is a splice of the Lisp form `(g x)`.

Each splice is an argument of the expression, and its type is what the
expression makes of it.  Like any binding without a signature it is
defaulted (`$n + 1` is an `Integer`), so give a type where another is
meant: `($n :: Int)`.  Definition blocks cannot have splices.

## Values

What crosses between Lisp and Haskell is decided by the Haskell type:

| Haskell | Lisp |
|---|---|
| `Int`, `Integer` | integer |
| `Double`, `Float` | `double-float`, `single-float` (from Lisp, any real) |
| `Char` | character |
| `Bool` | `T` / `NIL` |
| `()` | `NIL` |
| `String` | string |
| `[a]` | list (from Lisp, also a vector) |
| `(a, b, ...)` | list of the components |
| `Maybe a` | `NIL` for `Nothing`, `x` for `Just x` |
| `a -> b -> ... -> r` | function of that many arguments; a result of type `IO r` is run when it is called |
| `IO a` (inside another value) | function of no arguments that runs it |
| anything else | a `#<Haskell value>`, which can be spliced back in |

Lists, tuples and strings are converted whole: an infinite list does
not come back.  Numbers of other types (`Word8`, a `newtype` of `Int`)
are passed as they are.  `Maybe` of a type with a `NIL` value (`Maybe
Bool`, `Maybe [a]`) cannot tell `Just NIL` from `Nothing`.

A Lisp function spliced in where Haskell expects a function is called
with the converted arguments, and its value converted back:

```lisp
#@hs{ map $(lambda (x) (* x 10)) [1, 2, 3 :: Int] }#     ; => (10 20 30)
```

## Errors

A block that does not compile signals `yale-haskell:haskell-compile-error`
when it is macroexpanded, so at compile time, with the compiler's
messages.  A runtime error (`error`, `head []`, a failed pattern match)
signals `yale-haskell:haskell-error`, whose
`yale-haskell:haskell-error-message` is the error's message:

```lisp
(handler-case #@hs{ head ([] :: [Int]) }#
  (yale-haskell:haskell-error (e) (yale-haskell:haskell-error-message e)))
;; => "head{PreludeList}: head []"
```

## Packages, extensions and languages

```lisp
(yale-haskell:use-language :ghc2021)    ; GHC base's Prelude, GHC2021's extensions
(yale-haskell:enable-extensions "OverloadedStrings")
(yale-haskell:add-package-db "/path/to/.mcabal/yale-3.1.0.0/packages")
(yale-haskell:add-search-path "src/")   ; your own .hs modules
```

`use-language` takes `:haskell98` (the default), `:haskell2010`,
`:ghc2021` or `:ghc2024`, as the command line's flags; it forgets the
imports and definitions made so far.  Hackage packages generally need
`:ghc2021`.  Packages installed with MicroCabal (doc/PACKAGES.md) are
found in a package database; compile-time settings (these calls) go in
the `eval-when` that turns the syntax on, so that they hold when the
blocks are compiled too:

```lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (yale-haskell:enable-haskell-syntax (copy-readtable)))
  (yale-haskell:use-language :ghc2021)
  (yale-haskell:enable-extensions "OverloadedStrings")
  (yale-haskell:add-package-db "/path/to/.mcabal/yale-3.1.0.0/packages"))

#@hs{
  import Data.Aeson (encode, object, (.=))
  import qualified Data.ByteString.Lazy.Char8 as BL
}#

#@hs{ BL.unpack (encode (object ["name" .= ("yale" :: String), "year" .= (1991 :: Int)])) }#
;; => "{\"name\":\"yale\",\"year\":1991}"
```

A package's modules are compiled the first time they are imported (aeson
and its dependencies: about three minutes) and kept in the unit cache
(`~/.cache/yale-haskell`), which `bin/yale-haskell` shares: the aeson
example above then loads, compiles and runs in about 6 seconds.

`(yale-haskell:eval-haskell "TEXT")` compiles and evaluates a block's
text at run time, in the current package's module.

## How it works

The reader collects the block's text, replacing each splice by a
variable, and returns a macro form.  The macro compiles the block when
it is expanded, with the REPL's incremental compiler
(src/compiler/command-interface/embed.mumble): definitions extend the
package's module, and an expression `E` with splices `s0 ...` is
compiled as the binding `it = \s0 ... -> (E)`.  The expansion calls
that binding with the splices' values, converting them by the types the
compiler inferred.

A FASL holds the block's text, not its compiled code: loaded into a new
image, each block is compiled again the first time it runs (about ten
milliseconds each; the libraries come from the unit cache).
