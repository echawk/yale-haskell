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
and lens-like code, hardest); GADTs and TypeFamilies.

(2026-10-22: all of these are in; the `LANGUAGE` pragma switches each
extension per module.  GHC-EXTENSIONS.md is the current record.)

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

## optparse-applicative

Status (2026-10-15).  **optparse-applicative 0.18.1.0**
(`tools/conformance/optparse.py`), with prettyprinter 1.7.1 and
prettyprinter-ansi-terminal 1.1.3 from source: its test suite's 100
QuickCheck properties pass, most of them help texts rendered and
compared with the upstream golden files (tests/*.err.txt).  The one
adaptation: test.hs's `$(quickCheckAll)` main (Template Haskell) is
replaced by a list of its properties.  What it needed:

- **Language:** Arrows' `proc` notation (Examples/Cabal.hs); standalone
  deriving of a type from another module, newtype-derived for a class
  whose underlying instance has a context; hiding a data constructor by
  name (H98 5.3.4); `P..` as a qualified `.`; hiding a name a module
  does not export (GHC warns only); `MIN_VERSION_pkg` defined for
  `#ifndef`.
- **Libraries:** Control.Arrow, Control.Category, Data.Functor.Const,
  Numeric.Natural, Data.Text.Lazy as its own type and
  Data.Text.Lazy.Builder, System.Console.ANSI, ExceptT's Alternative,
  QuickCheck's `once`, `withMaxSuccess`, `ioProperty`, `isSuccess` and
  Test.QuickCheck.Property.
- **Flags:** `-D__GLASGOW_HASKELL__=906` for the package's own files (the
  examples define `(<>)` for GHC 7.2 and older otherwise).

## megaparsec (blocked when surveyed)

(2026-10-22: both blockers below have since been addressed on the way
to Agda: a class constraint at a family application resolves through
the given superclass, and an import cycle of source files is compiled
as one unit.  megaparsec has not been surveyed again.)


Surveyed 2026-10-15 (megaparsec 9.6.1, parser-combinators 1.3.0,
case-insensitive 1.2.1.0, in build/conformance/megaparsec).  Done on the
way: Data.Scientific, Data.Hashable, ReadP/ReadPrec, RWS, MonadPlus
implying Alternative, Control.Monad's Applicative functions.  What stops
it:

- **Associated type families with superclass contexts over them:**
  `class (Ord (Token s), Ord (Tokens s)) => Stream s where type Token
  s; type Tokens s`, and everything after relies on `Stream s` giving
  `Ord (Token s)`.  Declaring the associated types as top-level families
  would be easy; a superclass constraint on a family application needs
  dictionaries for non-variable superclasses.
- **Recursive modules** (`{-# SOURCE #-}` imports, .hs-boot files): Error,
  State and Stream import each other, as do Class and Internal.  Yale
  compiles a cycle as one unit only when a .hu file lists its modules
  together; the implicit units (one per file) report it as circular.
  Merging an import cycle's files into one unit automatically would fix
  this.

## Agda

Status (2026-10-22).  **Agda 2.8.0.2**, a dependently typed language and
proof assistant of about 160,000 lines (390 modules) of modern GHC Haskell, is the
current target: built with MicroCabal's Yale backend
(`tools/microcabal/mcabal -r install Agda`), so its whole dependency
chain of about 80 Hackage packages builds first (MICROCABAL.md).  What
it has needed so far is listed in CHANGELOG.md (3.1.0.0 and after):
GHC.Generics' representation, GADT refinement, equality superclasses and
given equalities on type families, constraint families, ImplicitParams,
ApplicativeDo, mutually recursive modules, and many smaller points.
It is done when it builds, its own test suite passes, and it checks
agda-stdlib (also the benchmark: the time to check the library against
a GHC-built Agda's).

## After Agda

1. Stress tests: FFI-heavy bindings (C, Python, Java; inline-java in
   FUTURE-TARGETS.md) and recent libraries that use many modern GHC
   language features, choosing those that are language rather than GHC
   internals, so that Yale can implement them.  Started 2026-10-25:
   packages' C code is compiled and loaded (doc/FFI.md), and X11, zlib,
   network, digest and cryptohash build; `forkIO` threads are real
   (2026-10-26).  A popular-package survey (93 packages,
   `tools/microcabal/hackage-survey.sh`) built 43 on 2026-10-26 before
   the fixes that followed it.
   - **A real xmonad** (the goal: Linux users building their own
     xmonad with Yale): the `X11` package (Xlib through `.hsc` files,
     `tools/microcabal/yale-hsc2hs`, and C stubs), then xmonad's
     executable and xmonad-contrib, which uses many extensions.  It
     can be tried here first against XQuartz (`/opt/X11/lib`) under an
     Xvfb or Xephyr display; Linux is the real target.  Needs: the
     binding's structs (`Event`, `WindowAttributes`) through
     `Storable`/`peekByteOff`, X error handler callbacks (`wrapper`
     imports), `forkProcess`/`executeFile` for spawning, and the X
     event loop's blocking `nextEvent`.
   - **Java through JNI**: the `jni` package from inline-java (C API
     calls, a JVM created from Haskell); OpenJDK 25 is installed.  Its
     callbacks from JVM threads need foreign threads calling into
     Yale's runtime: Haskell threads exist now, but a thread the JVM
     created is not yet given one (doc/FFI.md).
2. KiCS2, the Kiel Curry System (Curry compiled to Haskell): sketch what
   it needs first, then build it.
