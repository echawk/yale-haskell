# Future real-world testing targets

Candidates, beyond the ladder in [REAL-WORLD-TARGETS.md](REAL-WORLD-TARGETS.md),
to try compiling as the system grows. Each is framed as a test:
*can Yale Haskell handle this project, and what does it need?*  The
usual rules apply: clone into `ref/`, record workarounds as patches in
`tools/conformance/<target>/` (never edit the clone), a survey script that loads
each module in dependency order, and done when the project's own tests
or examples run with output matching GHC.

Ordered roughly by expected payoff.

## 1. inline-java — Java Native Interface bindings for Haskell

- **URL:** <https://github.com/tweag/inline-java/tree/master/jni>
- **Category:** FFI stress test
- Haskell/Java interop: inline Java code in Haskell modules, built on
  the JNI (a C API). The `jni` subpackage is the Haskell library that
  wraps `foreign import ccall` calls into the JNI C API — `JNIEnv*`
  pointers, callbacks into Haskell from Java, `jstring`/`jint`
  marshalling.
- **Why it is interesting:** it would really stress our FFI:
  `foreign import` of C functions taking and returning pointers,
  passing Haskell callbacks *down* into a foreign runtime (`foreign
  export` and `"wrapper"` imports, which exist now: doc/FFI.md), and
  keeping a foreign thread's call back into Haskell alive. Getting
  inline-java's JNI layer to run is a much harder and more realistic
  test of the FFI than anything in `bench/`.
- **What it needs:** a JVM on the system; callbacks from a foreign
  thread (Yale's runtime has Haskell threads since 2026-10-26, but a
  thread the JVM creates is not given one yet); the `inline-java`
  quasi-quoter itself needs QuasiQuotes, so start with the `jni`
  package.  One of the FFI stress tests planned after Agda
  (REAL-WORLD-TARGETS.md, "After Agda").

## 2. Template Haskell

- **URL:** <https://wiki.haskell.org/Template_Haskell>; the original
  design is Sheard and Peyton Jones, "Template Meta-programming for
  Haskell" (Haskell Workshop, 2002), and the current one is GHC's user
  guide, "Template Haskell".
- **Category:** the largest single missing language feature (the
  biggest gap on our "not supported" list, ahead of any type-system
  item)
- Quote, splice, and run Haskell code *at compile time*, where the
  spliced-in syntax tree is built by executing Haskell. Our compiler is
  Lisp-hosted and can already run compiled Haskell, which is the
  unusual advantage a Lisp-based implementation has here: a TH stage
  could be "compile this TH snippet to Lisp, run it, read the syntax
  back in".
- **Why it is interesting:** many real libraries (aeson,
  optparse-applicative, lens, `deriveGeneric`-style code) are unusable
  without it. Compiling a small subset (untyped TH: `Q Exp`, `Q Pat`,
  `Q Dec`, with `$(...)` splicing, no typed TH / THSplices) against a
  few small TH-using libraries would be the test.
- **What it needs:** a TH AST library in Haskell, a compiler API that
  accepts syntax trees from outside, and a staging story (the running
  TH program shares the compiler's image). This is a large project;
  keep it as a design question until the smaller gaps close (the
  current mission brief, `claude-prompt.md`, puts it out of scope).
  The design is now written up in TEMPLATE-HASKELL.md, and its
  milestones 1-4 (the library, quotes, expression and declaration
  splices, reify of types) are done (2026-10-18); QuasiQuotes and typed
  TH remain.

## 3. JHC — John Meacham's whole-program Haskell compiler

- **URL:** <https://wiki.haskell.org/index.php?title=Jhc>
  (sources: the `jhc` darcs repository and its GitHub mirrors)
- **Category:** a full compiler written in Haskell, as a target
- An old but complete Haskell-to-C compiler written in Haskell, with
  its own front end, typer, and a set of libraries. Its test suite and
  its own compiler source are a corpus of (older, but real) Haskell.
- **Why it is interesting:** bootstrapping is the ultimate test — if
  Yale Haskell can compile JHC's sources, it can compile a compiler.
  Even a partial result (its libraries, then its front-end modules) is
  a strong conformance signal, and its libraries and front end
  exercise records, type classes and the module
  system at a scale no bench program does.
- **What it needs:** mostly H98/H2010 coverage we already have, plus
  whatever its build demands (it uses DrIFT-style derivation and
  generated sources, so expect to check in pre-generated files as
  patches); the C back end is not
  needed to compile *its sources* — only to produce a working JHC.

## 4. rusholme — a toy Haskell compiler written in Zig

- **URL:** <https://github.com/adinapoli/rusholme>
  · <https://adinapoli.github.io/rusholme/>
- **Category:** a design to compare against; later perhaps a source of
  pass ideas; not yet a target
- An LLM-assisted, explicitly toy compiler for a subset of Haskell 2010,
  written in Zig: parse → typecheck → Core (System F_C) → GRIN → LLVM
  (native, Wasm, JIT), with C and JavaScript back ends planned.
- **Status (checked 2026-10-14):** early and experimental. It parses,
  typechecks, desugars, lambda-lifts and lowers to GRIN, with a
  tree-walking GRIN evaluator. Its optimisation milestone (M3) has not
  started, and it publishes no measured comparison with GHC (a
  `bench/` directory exists, but no results are shown).
- **Why it is interesting:** it is the closest existing design to ours,
  with a GRIN-style first-order IR between the type checker and the code
  generator. Once it has optimisation passes, compare them with the
  items in [GHC-OPTIMIZATIONS.md](GHC-OPTIMIZATIONS.md) §3. Until then,
  the GRIN papers (Boquist 1999) and our own
  [EVAL-APPLY-GRIN.md](../EVAL-APPLY-GRIN.md) remain the reference.
  Its `bench/` programs could later serve as a small corpus to run
  under both compilers.
- **Licensing note:** its licence is "not yet decided", so read it for
  ideas only and copy no code until it has a licence.

## 5. Helium — Utrecht's teaching compiler

- **URL:** <https://github.com/helium4haskell/helium>
- **Category:** a Haskell-subset compiler written in Haskell, as a
  target
- Helium (Heeren, Hage et al.) compiles a large subset of Haskell, with
  a focus on beginner-friendly type error messages, to code for the
  Lazy Virtual Machine (LVM) run by `lvmrun`; TextHint is its
  interactive front end.
- **Why it is interesting:** its front end and test programs must
  compile under our Haskell; more interestingly, it is another
  *Haskell-implemented Haskell compiler* (like JHC) whose sources are
  a real-world corpus. Its test suite of small programs with expected
  output (and expected type-error messages) is a cheap regression
  corpus once it compiles.
- **What it needs:** its attribute-grammar sources (uuagc) generated
  ahead of time and checked in as patches; the LVM to run its own
  tests; language coverage comparable to JHC's.

## 6. UHC — the Utrecht Haskell Compiler

- **URL:** <https://github.com/UU-ComputerScience/uhc>
- **Category:** a complete small Haskell compiler, as a target
- A full Haskell 98 compiler written in Haskell (Utrecht University),
  with front end, back end to C, and its own runtime.
- **Why it is interesting:** smaller than JHC and cleaner, so the most
  likely of the compiler targets to actually compile end to end first.
  UHC is also a useful *reference implementation* while fixing our
  type checker: a second independent H98 compiler whose test suite
  gives expected results without relying on GHC.
- **What it needs:** mostly standard H98, but UHC is built with its own
  tools (shuffle, uuagc), so the generated Haskell has to be produced
  once with those tools and checked in as patches; its C output is not
  needed to compile it.

## 7. NHC98

- **URLs:** the project has moved around over the years; the long-time
  home was <http://www.nongnu.org/nhc98/> and sources were on Source
  Forge (the `nhc98` project) — both now 404, so use a surviving
  mirror or the Internet Archive as the source (we already read
  nhc98's libraries for the Text.Printf / PrettyPrint ports).
- **Category:** one of the H98-era reference implementations (with
  Hugs and GHC); read-only source of ideas
- A Haskell 98 compiler from York, small and close to the Report,
  with a complete H98 library set (some already ported: Text.Printf,
  PrettyPrint, parts of containers 0.3).
- **Why it is interesting:** (a) compiling NHC98's own sources is a
  historical full-compiler target; (b) its libraries and test programs
  are the purest H98 corpus in existence — the right yardstick when we
  want to know whether a behaviour is "correct H98" rather than "what
  GHC happens to do" (relevant to the open questions about Inf/NaN,
  defaulting, and the 62-bit `Int`).
- **Licensing note:** as before, nhc98 is **read-only** — its licence
  does not permit copying into this project; we copy ideas and
  behaviour, not code (REVIVAL-PLAN §3).

## 8. KiCS2 — the Kiel Curry System

- **URL:** <https://www-ps.informatik.uni-kiel.de/kics2/>
- **Category:** a compiler for another language, written in Haskell
  and Curry, that compiles Curry to Haskell
- KiCS2 translates Curry (a functional logic language: Haskell's syntax
  plus nondeterminism and free variables) into Haskell and runs it with
  a Haskell compiler; its front end and much of its runtime are Haskell
  packages.
- **Why it is interesting:** both a large Haskell codebase to compile
  and, once it builds, a generator of large Haskell programs to run.
- **What it needs:** surveyed in [KICS2.md](KICS2.md) (2026-10-22): its
  compiler's Haskell is generated once with the distribution's kics2c,
  and the generated code needs QuantifiedConstraints.

---

### Suggested order

UHC (smallest full compiler) → JHC → Helium (all three: "can we
compile a Haskell compiler?"), rusholme as a design to revisit once its
optimisation passes exist (it is a reference for
[GHC-OPTIMIZATIONS.md](GHC-OPTIMIZATIONS.md) more than a target), NHC98 as a reference yardstick rather than
a milestone.  Since 2026-10-22 the order after Agda is: stress tests
(inline-java's jni among the FFI-heavy ones, and recent libraries using
modern GHC features), then KiCS2.
