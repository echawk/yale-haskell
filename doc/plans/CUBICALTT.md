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

| example | Yale, first | Yale, now | GHC -O | ratio now |
|---|---|---|---|---|
| univprop | 81.6 s | 27.0 s | 27.8 s | 0.97× |
| csystem | 75.4 s | 17.6 s | 19.1 s | 0.92× |
| torsor | 35.3 s | 13.0 s | 9.1 s | 1.4× |
| opposite | 20.0 s | 5.0 s | 4.6 s | 1.1× |
| category | 19.0 s | 5.7 s | 4.6 s | 1.2× |
| grothendieck | 11.7 s | 6.4 s | 2.9 s | 2.2× |
| hz | 5.4 s | 3.2 s | 1.1 s | 2.8× |
| setquot | 4.9 s | 2.9 s | 1.0 s | 2.9× |
| the other 34 | 0.7–2.1 s | 0.6–1.9 s | 0.04–0.6 s | mostly start-up |

"First" is the round that brought cubicaltt up; "now" is after the
optimizations below (2026-10-12), measured two examples at a time on a
loaded machine.  Most of the change is one thing: tuple instances.
cubicaltt compares environments (`Eq Ctxt`, `Eq Loc`, an `Env` that is a
4-tuple) constantly, and every tuple comparison used to build `Eq`
dictionaries at run time and go through a generic loop
(`PreludeTuple.tupleEq`); the Prelude now has GHC's instances for 2- to
7-tuples as ordinary code, which the specializer and inliner handle.

Compiling cubicaltt from scratch, libraries
included, takes about a minute; the unit cache makes later runs start in
under a second.

## Two more checkers: LambdaPi and Mini-TT

    tools/conformance/typecheckers.py [-v] [NAME ...]

Two small dependently typed checkers of the same family, smaller and
older than cubicaltt, run unchanged, with output identical to GHC's:

- **LambdaPi** (Löh, McBride and Swierstra's tutorial implementation,
  2010; about 1,200 lines): Haskell 98 with parsec, old mtl's
  `Control.Monad.Error`, readline and the Prelude's `catch`.  It runs in
  Yale's plain Haskell 98 mode.  Its module is `LP`, so a two-line `Main`
  wrapper calls it (GHC needs `-main-is` for it).  Sessions are fed to
  its interpreter: `smoke.in` loads its prelude and browses it;
  `bench.in` does unary arithmetic by `natElim` (factorials, powers to
  2^19, `natEq` on the results), vectors and proofs.
- **Mini-TT** (Coquand, Kinoshita, Nordström and Takeyama, 2009, the
  paper's ~400 lines with a BNFC parser): checks the paper's examples
  and `bench.mtt`, where types are computed by unary arithmetic
  (`T (pow two eleven)`), which the conversion check must normalize.

The GHC builds need patches (no `Control.Monad.Error` in mtl 2.3, no
readline package, no Prelude `catch`, `<>` in the Prelude); Yale runs
the sources as written.  Neither repository gives a licence, so the
script fetches them at pinned versions and nothing of theirs is
committed; Mini-TT's parser is generated at run time (BNFC_BIN).

What they needed: parsec 3.1.18, ported unchanged (BSD, with its
`Text.ParserCombinators.Parsec` compatibility modules), as a `:package`
unit, which gives a library unit base's Prelude in every mode;
CPP's `MIN_VERSION_pkg`; `Control.Monad.Error`, `Control.Monad.Cont`,
`System.Console.Readline`, `Data.Data`, `Data.Text.Lazy`; `sconcat` and
`stimes` as `Semigroup` methods and NonEmpty's instances in
PreludeModern, as base has them; and these fixes:

- instance methods of a class imported only qualified (`instance
  Semigroup.Semigroup ... where (<>) = ...`);
- `(C a => t)`, a whole signature in parentheses;
- the monomorphism restriction generalized type variables that pending
  constraints still mentioned (`Eq (t b)` once `null` is Foldable's, a
  variable determined only by a functional dependency), which then could
  not be defaulted;
- a signature's multi-parameter constraints did not improve the body's
  by functional dependency when the dictionaries were attached, so a
  type variable only in the constraints (`(Show t, Stream s m t) =>
  s -> m String`) was lost;
- `import Prelude hiding ((*))` and a definition of `*`: a Prelude class
  method could not be redefined (and the hidden one was still used);
- an explicit `import Prelude hiding (...)` brought the Haskell 98
  Monad's `fail` back under `--modern-prelude`.

| benchmark | Yale | GHC -O | ratio | Yale GC | GHC GC | allocated, Yale / GHC |
|---|---|---|---|---|---|---|
| lambdapi-bench | 3.9 s | 1.2 s | 3.2× | 2.2 s | 0.32 s | 4.4 / 3.1 GB |
| minitt-bench | 3.1 s | 1.2 s | 2.6× | 1.1 s | 0.53 s | 4.0 / 2.5 GB |

These evaluators are dominated by closures and thunks.  Yale allocates
1.5–1.6 times GHC's bytes (a thunk is a cons plus a closure, a
constructor a vector with its tag) and spends much more time in SBCL's
collector than GHC in its own; the mutator alone is 1.6× (LambdaPi) and
2.4× (Mini-TT) GHC's.  Closing that is representation work (smaller
thunks and constructors) and fewer thunks (stronger demand analysis),
not a missing simplifier pass.

## Next: libraries

Ordered by how many real programs need them and how much work they are.
Each is mostly Haskell; the obstacle, where there is one, is GHC
internals.

| library | needed by | approach | size |
|---|---|---|---|
| parsec 3 | most parsers that are not generated | **done** (2026-10-12): the unchanged source, a `:package` unit | small |
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

Programs of the same kind as cubicaltt to try next, each a step up
(LambdaPi and Mini-TT, suggested here first, now run):
**Elm 0.x's compiler** and a **Scheme interpreter in the "Write Yourself
a Scheme" style** need parsec; a **terminal roguelike** (no graphics
library needed) would exercise records, State and Data.Map in a long
interactive loop.

## Next: optimizations

Done in this round (2026-10-12), measured:

- **Tuple instances as code** (2- to 7-tuples, PreludeCore.hs): the
  largest win, above.  A profile had put 74% of torsor's samples under
  the generic `tupleEq` and its run-time dictionaries (`TUPLEEQDICT/L`).
- **Specializer budget** 60 → 200 per module: Eval, Connections and
  Exp.Abs had reached 60; torsor allocates 4% less.
- **Block-buffered stdout** when it is not a terminal (6% of torsor was
  a `write` per output line).
- **Blackholing drops the closure** while a thunk is evaluated, as GHC's
  does (no measurable change on these benchmarks, but it removes a
  space leak).
- Tried and dropped: writing evaluated values back into the fields that
  held their thunks (GHC's collector removes such indirections; doing
  it in the mutator measured no gain).

What the profiles show now:

- cubicaltt: string equality (`Eq [Char]`, specialized, 17% of torsor)
  and `Data.List.unionBy` under the nominal `support` functions; the
  same work GHC does.  torsor and grothendieck remain at 1.4× and 2.2×.
- LambdaPi and Mini-TT: GC (above), then closure and thunk allocation in
  their evaluators.

In order of expected effect (GHC-OPTIMIZATIONS.md §3 has the full list):

1. **Smaller thunks and constructors**: a thunk is a two-word cons plus
   a closure; a constructor is a vector with a tag word.  A one-object
   thunk (a funcallable instance or a closure with a mutable slot) and
   struct instances for constructors (SBCL allocates those inline; a
   simple vector is a call on arm64) would cut allocation and GC.
2. **Demand analysis upgrades** (fewer thunks): absence, and strictness
   of constructor fields and of arguments through `>>=` of the
   transformer stacks these checkers use.
3. **Worker/wrapper with CPR** (unboxed returns through CL `values`):
   the ExceptT/ReaderT layers return `Either` values tested at once.
4. **Case of case with join points**.
5. **A size-based inliner**.

Measure with `tools/conformance/cubicaltt.py torsor grothendieck`,
`tools/conformance/typecheckers.py`, and `YALE_HASKELL_TIME=1` for GC
time and bytes allocated (which do not depend on machine load).
