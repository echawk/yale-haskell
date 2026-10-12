# cubicaltt: a proof assistant as the modern-Haskell test program

Status: done (2026-10-12).  All 43 of cubicaltt's examples that GHC can
check type-check under Yale Haskell with output identical to GHC 9.14's
(`tools/conformance/cubicaltt.py`).  This page records why cubicaltt was
chosen, what it needed, what it found, how fast it runs, and what comes
next: libraries to port and optimizations to build.

## Why cubicaltt

The aim was one real program that uses most of what Yale Haskell now
supports from GHC.  Agda is the program of this kind people know, but it
is about 100,000 lines and depends on dozens of packages and Template
Haskell, so it is out of reach.  cubicaltt (Cohen, Coquand, Huber,
Mörtberg; https://github.com/mortberg/cubicaltt, MIT licence) is the same
kind of program at a feasible size: a type checker and evaluator for
cubical type theory, about 3,000 lines of Haskell plus a generated
parser, with 43 example proof files (univalence, higher inductive types,
the integers as a quotient, category theory).  Checking a proof file
runs the evaluator hard: normalization in a nominal setting with finite
maps of faces, so it is also a benchmark.

What it uses:

| area | what |
|---|---|
| extensions | TupleSections, FlexibleInstances, OVERLAPPABLE/OVERLAPPING instances, GeneralizedNewtypeDeriving (through an instance with a context), PatternSynonyms (used across modules), LambdaCase, MagicHash and GHC.Exts primops, CPP (with `#include` and multi-line macro calls), pattern guards |
| generated code | BNFC 2.9 abstract syntax, printer and layout resolver; an Alex lexer; a Happy 2.0 parser (which always emits GHC code: `Addr#` literal tables, `indexInt32OffAddr#`, `tagToEnum#`) |
| libraries | containers (Data.Map, Data.Set), mtl (ReaderT, ExceptT, Identity), pretty, QuickCheck (Arbitrary instances), haskeline, time, directory, filepath, GetOpt, Text.Printf, Control.Exception |
| source | files with CRLF line ends |

## How to run it

    tools/conformance/cubicaltt.py [-v] [-j N] [NAME ...]

The script fetches the sources into `ref/cubicaltt` at the pinned commit
(9baa6f2), copies them with the committed generated parser
(`tools/conformance/cubicaltt/Exp/`, regenerate with
`bnfc --haskell -d Exp.cf; alex Exp/Lex.x; happy Exp/Par.y`) and two
stub C headers (`include/`) into `build/conformance/cubicaltt`, and
checks each example with `cubical -b NAME.ctt` from the examples
directory.  It compiles with

    bin/yale-haskell --haskell98 --modern-prelude --cpp \
      -I tools/conformance/cubicaltt/include -D__GLASGOW_HASKELL__=914 Main.hs

The source needs no changes.  lambek.ctt is left out: it fails under GHC
too and then reads its prompt forever.

## What it needed

Libraries (lib/haskell98): Test.QuickCheck (a QuickCheck 2 subset: Gen,
Arbitrary with shrink, CoArbitrary, Property, `==>`, forAll,
quickCheck), System.Console.Haskeline (InputT over a history; reads
lines from a non-terminal as GHC's does), Data.Time.Clock (UTCTime,
NominalDiffTime in picoseconds, `getCurrentTime`, `diffUTCTime`, with
time's Show), System.Console.GetOpt (Hugs's), System.FilePath
(filepath's Posix module), Control.Monad.Identity, System.Random,
Data.Bool, GHC.Err, GHC.Num, Text.Show, and GHC.Exts's `Addr#` (a byte
array), the `index…OffAddr#` reads, sized-integer conversions,
`tagToEnum#` and `unsafeCoerce#`.

Compiler:

- **PatternSynonyms across modules.**  The defining module's scope
  phase resolves each synonym's pattern into a template of plain data
  (constructors as defs) attached to the builder `pattern%P`'s def, and
  the interface records it (`register-pattern-synonym`).  A use of `P`
  or `M.P` in another module finds the builder by name and instantiates
  the template.  Every synonym now has a builder, so one-way synonyms
  can be exported too.
- **Overlapping instances.**  A class may have several instances for
  one type constructor when the heads are flexible (`Print [a]`,
  `Print [Imp]`, `Print String`).  At a type, the most specific matching
  instance is used (`lookup-instance/type`); while the arguments are
  undecided the general one matches.  The pragmas are accepted and not
  needed.
- **A flexible head with undecided arguments** (`Nominal (Map Face a)`
  needed at `Map t a`): when it is the only instance for the type
  constructor, the type is unified with the head instead of rejected.
- **GND through an instance with a context** (`newtype Name = Name
  String deriving Arbitrary`, where the list instance has `Arbitrary a
  =>`): derived as `deriving newtype` is, the field type's methods
  coerced.
- **CPP**: `#include` of stub headers with C comments; command-line
  `-D` macros only for the program's files, not the libraries'; a
  function-like macro call spanning lines (Happy's `DEBUG_TRACE(...)`).
- **Lexer**: MagicHash string literals (`"..."#`, an `Addr#`) and
  negative literals (`-1#`); qualified operators starting with a dot
  (`Data.Bits..&.`); CRLF line ends; qualified boxing constructors
  (`Happy_GHC_Exts.I#`).
- **Parser**: a record pattern `C{}` in a pattern guard.
- **Imports**: under `--modern-prelude`, `import Prelude hiding (x)`
  also hides `x` from the implicit PreludeModern import (CTT.hs hides
  `<>`); Control.Monad exports `MonadFail`.
- **A miscompilation in the specializer** (see below).

## The specializer bug it found

`T.sequence` over a `Map` of `ReaderT Env (ExceptT String IO)` actions
crashed (`The value #(1 …) is not of type FUNCTION`).  The FLIC was
right; the Lisp called `<*>@spec/OPT`, a function of four parameters,
with three arguments.  A call rewritten to a specialized function keeps
its application node, whose `saturated?` flag was set when it called the
original; the specialized copy later gained a parameter (IO's state, by
eta expansion), and the postoptimizer marked saturated calls but never
cleared a stale flag.  It now does (`postoptimize-app-aux`).  Found by
bisection: `YALE_HASKELL_NO_SPECIALIZE` takes a list of module names,
and `YALE_HASKELL_SPECIALIZE_LIMIT=n` / `YALE_HASKELL_SPECIALIZE_TRACE=1`
make and list only the first n specializations of a run.
`YALE_HASKELL_DEBUG=1` now also prints a backtrace for an error raised
while an IO primitive forces its argument.

## Speed

Wall-clock time to check each file, one at a time unless noted, on an
Apple M-series machine; Yale's includes about 0.6 s of start-up and
loading the compiled program.

| example | Yale | GHC -O | ratio |
|---|---|---|---|
| univprop | 81.6 s | 27.8 s | 2.9× |
| csystem | 75.4 s | 19.1 s | 3.9× |
| torsor | 35.3 s | 9.1 s | 3.9× |
| opposite | 20.0 s | 4.6 s | 4.4× |
| category | 19.0 s | 4.6 s | 4.1× |
| grothendieck | 11.7 s | 2.9 s | 4.0× |
| hz | 5.4 s | 1.1 s | 4.7× |
| setquot | 4.9 s | 1.0 s | 4.9× |
| the other 35 | 0.7–2.1 s each | 0.04–0.6 s | mostly start-up |

(The Yale column was measured with four examples running at once, so it
is slightly pessimistic.)  Compiling cubicaltt from scratch, libraries
included, takes about a minute; the unit cache makes later runs start in
under a second.

## Next: libraries

Ordered by how many real programs need them and how much work they are.
Each is mostly Haskell; the obstacle, where there is one, is GHC
internals.

| library | needed by | approach | size |
|---|---|---|---|
| parsec 3 | most parsers that are not generated | port the source: it needs MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, RankNTypes, all present | small |
| megaparsec | modern parsers | after parsec; needs TypeFamilies (present) and a Stream class over Text | medium |
| optparse-applicative | almost every command-line tool | the source is plain Applicative code over Text.PrettyPrint.ANSI; port with a no-colour prettyprinter | medium |
| a packed Text and ByteString | anything that reads files | keep the API, change the representation to Lisp strings and `(unsigned-byte 8)` vectors (GHC-EXTENSIONS.md, "What running modern Haskell needs") | medium |
| vector | numeric code, many libraries | boxed `Vector` over Lisp simple-vectors, unboxed over specialized arrays; no stream fusion at first | medium |
| unordered-containers, hashable | aeson, many servers | HashMap as a hash array mapped trie (pure Haskell) or as Data.Map behind the API | small (behind the API) |
| aeson (a subset) | JSON | Value, encode/decode, a FromJSON/ToJSON without Generic deriving | medium |
| process | tools | `readProcess`, `system`, through SBCL's run-program | small |
| real haskeline | interactive tools | line editing through the REPL's editor (src/compiler/command-interface) | medium |
| QuickCheck's full API | test suites | the rest of QuickCheck 2: Gen combinators, `quickCheckWith`, labels, `Testable` instances for functions of more arguments | small |
| stm with threads | concurrent programs | needs the threaded runtime first (GHC-EXTENSIONS.md tier 4) | large |

Programs of the same kind as cubicaltt to try next, each a step up:
**LambdaPi** (Löh, McBride and Swierstra's tutorial checker) and
**Mini-TT** are small dependently typed checkers that should run now;
**Elm 0.x's compiler** and a **Scheme interpreter in the "Write Yourself
a Scheme" style** need parsec; a **terminal roguelike** (no graphics
library needed) would exercise records, State and Data.Map in a long
interactive loop.

## Next: optimizations

A profile of grothendieck.ctt (`YALE_HASKELL_PROFILE=1`) puts most of
the time in forcing thunks (80% of samples below `FORCE-THUNK`) and, as
self time, in derived equality: `Eq [a]` specialized at CTT's types,
`Eq Loc`, `Eq Ctxt`, and `tupleEq`, `Data.List.unionBy` and
`deleteFirstsBy` under the nominal `support` functions.  GHC does the
same comparisons; what Yale adds is visible in two rows:
`TUPLEEQDICT/L`, a tuple's `Eq` dictionary built at run time from its
components' on every use (`src/runtime/tuple-prims.mumble`), and the generic
`tupleEq` it dispatches through.  The specializer makes Map's `Ord`
dictionaries at `Name` and `Face` constant already (`compare@spec`).
In order of expected effect here (GHC-OPTIMIZATIONS.md §3 has the full
list):

0. **Constant tuple dictionaries**: treat `tupleEqDict d1 d2` (and the
   Ord, Show and Ix ones) with constant arguments as a constant
   dictionary, so the specializer and selector folding see through it
   as they do for `dict-Eq-List dict-Eq-Char`; and derive a tuple's
   `==` per arity instead of through the generic runtime function.
   Cheap, and it removes the 3% spent building dictionaries.
1. **Worker/wrapper with CPR** (unboxed returns through CL `values`):
   the ExceptT/ReaderT layers return `Either` values that are tested at
   once; a constructed-product return would avoid the allocation.
2. **Case of case with join points**: the `>>=` of ExceptT inlined into
   ReaderT's leaves `case (case … of Left → …; Right → …) of …`, which
   `let-case-of-case` handles only for small bodies.
3. **A size-based inliner**: much of the remaining dictionary-passing
   overhead is small library functions without `Inline` annotations.
4. **SpecConstr**: the evaluator's recursion over `Val` with known
   constructors at recursive calls.
5. **Update avoidance** for single-entry thunks (usage analysis):
   evaluation-heavy code creates many thunks forced exactly once.

Measure with `tools/conformance/cubicaltt.py csystem univprop category`
before and after; the per-example ratios above are the baseline.
