# Plan: real-world Haskell targets

Conformance so far is the Haskell 98 Report, nofib (43 pass) and our
own tests.  The next measure is real code people use.  The difficulty
is less the language than *base*: most code since ~2015 assumes GHC's
modern base (Applicative ⇒ Monad, Semigroup/Monoid, Foldable,
Traversable, MonadFail) and a few extensions.

## The ladder

Status (2026-10-12): rungs 1, 2 (as a QuickCheck 2 subset), 3 (as
parsec 3, which LambdaPi uses through the parsec 2 API), 4 (Alex and
Happy 2.0 output, the GHC-specific kind included), 6 and 7 are climbed,
and past the ladder cubicaltt (CUBICALTT.md), a 3,000-line proof checker
using mtl, containers and a dozen GHC extensions, runs unchanged with
output identical to GHC's.  CUBICALTT.md lists the libraries to port
next.

Each rung is a real codebase, chosen to need one new thing at a time.

1. **`pretty`** (Text.PrettyPrint.HughesPJ): Haskell 98, no
   extensions.  Tests the compiler on idiomatic library code and gives
   us a pretty printer.
2. **QuickCheck 1.x**: Haskell 98 plus `Random`.  Brings property
   testing to our own test suite.
3. **parsec 2.x**: Haskell 98 (parsec 3 needs MultiParamTypeClasses and
   FlexibleInstances).  A real parser library.
4. **A Happy- or Alex-generated parser**: both can emit plain Haskell 98
   (no GHC-specific output); large, generated, table-driven code is a
   good stress test of compile time and the GRIN back end.
5. **MicroCabal** (MICROCABAL.md): Haskell 2010 by design; needs the
   Applicative layer and one multi-parameter class.
6. **The modern-base Prelude** (MICROCABAL.md step 2b) — after it,
   `containers`-style code, `mtl`-style monad transformers (need
   MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances),
   and parsec 3 become reachable.
7. **CPP**: a `{-# LANGUAGE CPP #-}` pass (a small C-preprocessor
   subset in Lisp: `#if`, `#ifdef`, `#define` of simple macros,
   `MIN_VERSION_x(a,b,c)`), needed by most Hackage packages.

## How to run a rung

- Clone into `ref/` (gitignored).  Record any workaround as a patch in
  `tools/conformance/<target>/`, never as edits to the clone.
- A survey script that loads each module in dependency order and
  prints the first error (as tools/microcabal/survey.sh does).
- Done when the package's own tests or examples run with output
  matching GHC; then add a small representative program to
  `tests/haskell98/` so the rung stays climbed.

## Extensions likely to be needed, roughly in order of payoff

MultiParamTypeClasses + FunctionalDependencies; FlexibleInstances /
FlexibleContexts; ScopedTypeVariables (explicit `forall`, scoped type
variables in local signatures); TupleSections; LambdaCase;
BangPatterns; GeneralizedNewtypeDeriving; RankNTypes (needed by `ST`
and lens-like code, hardest); GADTs and TypeFamilies (out of scope for
now).  The `LANGUAGE` pragma is ignored today; it should become a
switch per extension once the first one exists.

## Beyond the ladder: xmonad and darcs

Status (2026-10-13).

- **xmonad 0.18.1** (`tools/conformance/xmonad.py`): the pure core
  (XMonad.StackSet) and its 107 QuickCheck properties, under
  `--modern-prelude` with a types-only stand-in for the X11 binding.
  All 107 match GHC 9.14's output.
- **darcs 1.0.9** (`tools/conformance/darcs.py`): the whole program,
  about 25,000 lines of 2007 Haskell 98 written for GHC 6.6, built with
  `--haskell98 --cpp -D__GLASGOW_HASKELL__=606` and its C helpers
  loaded with `-l`.  A scripted 25-step session (init, add, record,
  whatsnew, changes, get, pull, mv, a conflict with its markers, revert,
  diff, annotate, unrecord, check) matches `darcs/session.out`.  With
  `--unit`, darcs's own unit tests (unit.lhs, QuickCheck 1) run, about a
  minute: in a typical run 33 properties pass and 14 end "Arguments
  exhausted", and from run to run zero to three are falsified.  The
  exhausted ones are darcs's own generator limits: it never produces the
  Conflictor patches two subcommutes handle, and some subcommutes never
  fail.  Every falsification seen (double commute, nontrivial commutes
  of `commute` and `force_commute`, conflict resolution validity)
  involves a merger of conflicting patches or a `-conflict` name, the
  corner of darcs 1's conflict handling that darcs 2 replaced; the double
  commute follows `commute_nameconflict` by hand.  With the random seed
  fixed, the results are identical with the optimizers on, off, and on
  the FLIC back end.  GHC 6.6 is not available to compare against.

  What darcs needed, in the library: a System.Posix subset
  (posix-runtime.lisp over sb-posix: file status, modes, links, open/dup,
  fdToHandle, signals), Text.Regex (over cl-ppcre), Text.Html,
  Debug.QuickCheck (QuickCheck 1), hPutBuf/hGetBuf,
  addForeignPtrFinalizerIO, Data.Array.IArray, record CalendarTime and
  TimeDiff, and the GHC 6 module names (Ptr, CString, MarshalAlloc,
  ...).  In the build copy only: base 3's Control.Exception (the
  Exception data type) is `darcs/OldException.hs`, configure's output is
  `darcs/Workaround.hs`, and `darcs/DarcsUtils.patch` replaces a use of
  GHC.IOBase.  In the compiler: an operator at the start of a line ends a
  `do` block (the layout rule's parse-error(t)), `Monad (m s)` contexts,
  and the unit cache now records a program's own units by absolute name,
  so a program run from another directory reuses its compiled units
  (darcs went from 11 s to under 1.5 s a command).

## husk-scheme

Status (2026-10-14).  **husk-scheme 3.20** (`tools/conformance/husk.py`),
an R7RS Scheme interpreter in about 11,000 lines of Haskell (parsec,
mtl's ExceptT over IO, existential types, IORef environments, hygienic
and explicit-renaming macros, first-class continuations, SRFIs 1, 2, 9,
39), runs unchanged; only Cabal's generated Paths_husk_scheme is
supplied.  Its own test suites (run-tests.scm, about 900 assertions;
run-tests7.scm, R7RS libraries; r5rs_pitfall.scm) print exactly what
GHC 9.14's build of the same sources prints, including the one
numerical assertion GHC's build also fails (2.9999999999999996 for 3).
The suite takes 3.1 s against GHC's 1.0 s (Yale's includes about 0.7 s
of loading compiled units).

What husk needed:
- **Language:** an explicit `{` opens an explicit layout context, as the
  Report's L does (a record declaration's `}` in column 1); a synonym for
  a partial application (`type ThrowsError = Either LispError`) used
  over-applied in a data type declared before it; one application for
  `(Either e) a`; an existential pattern's rigid type variable unified
  with the monomorphic variables of its match.
- **Prelude:** arrays with empty bounds (`listArray (0, -1) []`), and
  Haskell 98's `Functor (Array a)` instance.
- **Libraries:** Data.Knob (in-memory handles, for string ports),
  Data.ByteString.UTF8, Data.Fixed, Data.Unique, Data.Time.Clock.POSIX,
  System.CPUTime, getEnvironment, Haskeline's Completion module.

## happy

Status (2026-10-14).  **happy 1.20.1.1** (`tools/conformance/happy.py`),
the parser generator, about 7,000 lines including its own happy-generated
GHC-style parsers (MagicHash, `GHC.Exts` primops, OPTIONS -X pragmas),
runs unchanged.  On its 33 test and example grammars with its test
suite's flag sets (none, -a, -g, -gc, -gac), every generated parser,
grammar info file and message is identical to GHC 9.14's happy: 166 of
166 (compared by SHA-256, tools/conformance/happy/expected.sha256).

issue93.y, a 1,250-line grammar, is kept as a performance guard (a time
limit, ISSUE93_LIMIT): it ran for over an hour, from two causes now
fixed.  The optimizer's let-hoist-lambda moved a let into the lambda
after it whatever the let computed, so `precalcClosure0 g = \n -> lookup
n table where table = ...` rebuilt the closure table for every lookup
(ErlParser.ly: 45 s and 67 GB allocated, now 0.3 s and 0.5 GB); and the
Report's `sortBy` (an insertion sort, O(n^2), whose chain of insertBy
thunks exhausted the 4 GB heap), now GHC's merge sort.  It takes about
45 s against GHC's 8 s.
