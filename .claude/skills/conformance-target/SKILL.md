---
name: conformance-target
description: How to bring up a real-world Haskell target or Hackage package with Yale Haskell and measure conformance against GHC. Covers ref/ clones (never edited), patches in tools/conformance/<target>/ and tools/microcabal/patches/, tools/microcabal/mcabal and the MicroCabal submodule, CABALDIR, the runners in tools/conformance/ (extensions, nofib, ghc_testsuite, agda, real-world), licence hygiene, and recording counts in doc/harness/baselines.md. Use for Milestones 2–5 tickets, any Hackage package work, or any change to tools/conformance/.
---

# conformance-target

## Principles (non-negotiable)
1. **Never edit a clone or the submodule.** Clones live in `ref/` (gitignored).
   Workarounds are patches in `tools/conformance/<target>/` or
   `tools/microcabal/patches/<package>.patch`, one per package. Prefer fixing
   the compiler over patching the package. Each patch says why it exists.
2. **GHC 9.14.1's output is the expected output.** Runners compare against GHC,
   never against an earlier Yale run.
3. **Counts only go up.** Record each runner's counts in
   `doc/harness/baselines.md` with the date and the exact command. A lowered
   count is a regression.
4. **Licence hygiene.** Copy only permissively licensed code into the
   repository, keeping notices. No nhc98 or copyleft code. Vendored test corpora
   need a provenance file (source, commit, licence, date).
5. **No real network in tests.** Fetching packages is setup, not a test. Tests
   run offline from what was fetched.

## MicroCabal and Hackage
```sh
git submodule update --init tools/microcabal/MicroCabal   # once (mcabal also does this)
export CABALDIR=$PWD/build/mcabal                          # keep installs inside the repo's build/
tools/microcabal/mcabal -r install <package>               # see doc/PACKAGES.md
```
- The backend is the submodule's `yale-backend` branch (pinned at 60337f9 on
  2026-11-12).
- Patches are found through `YALE_MCABAL_PATCHES` (default
  `tools/microcabal/patches`).
- `doc/PACKAGES.md` and `doc/plans/MICROCABAL.md` list what builds.
- Packages that import `.Internal` modules of libraries the compiler ships in
  part (containers, text, bytestring) may need the real package fetched
  (`replacedPackages`, `doc/plans/ROADMAP.md` item 5).

## Runners (`tools/conformance/`)
```sh
tools/conformance/extensions.py         # one program per GHC extension vs GHC
tools/conformance/nofib.py --try-all    # nofib vs GHC
tools/conformance/h2010-exports.py      # 2010 Report export lists (needs ref/haskell2010-report)
tools/conformance/ghc_testsuite.py      # GHC 9.14.1 compile_and_run tests (needs ref/ghc-testsuite)
tools/conformance/{cubicaltt,typecheckers,happy,husk,darcs,xmonad,optparse}.py
tools/conformance/agda.py               # (YHS-2.1)
```
- Run long ones under `tools/bound`.
- `make ref` creates most clones. `ref/ghc-testsuite` uses the sparse-clone
  recipe in `ref/README.md`.
- Results go under `build/conformance/<runner>/`. Copy the decisive summary into
  `notes/<ID>/`.

## Bringing up a package or program (procedure)
1. Build it and save the first error in `notes/<ID>/`.
2. Classify the error:
   - a compiler bug: reduce it to a test in `tests/haskell98/` with
     GHC-derived output, then fix it;
   - a missing library function: add it to `lib/haskell98/`, with a test;
   - a GHC-only feature that will not be supported: write a patch with a
     comment, after reviewer approval.
3. Repeat until it builds. Then run its own tests or a smoke program, and
   compare with GHC.
4. Record the result in the covering plan document
   (`doc/plans/REAL-WORLD-TARGETS.md`, `MICROCABAL.md`, `CONFORMANCE.md`) and in
   `doc/harness/baselines.md`.

## Testing (required)
- A reduced regression test in `tests/haskell98/` for every compiler fix found
  through a target.
- Runner counts before and after, in the handoff note.
- No runner count lowered (`doc/harness/baselines.md`).

## Pitfalls
- **Install location.** `CABALDIR` defaults to `~/.mcabal`, outside the
  repository. Always set it.
- **Module names are global** in Yale (`doc/plans/ROADMAP.md` item 4). Two
  packages with the same module name conflict. Do not add more global-name
  assumptions (north-star hook).
- **Template Haskell is partial.** Packages using it go through
  `src/compiler/th/`, not patches that stub it out silently.
- **Compile time.** Some packages compile for minutes (aeson about 3 minutes
  cold; vector modules about 20 s each). Budget with `tools/bound` and record
  wall times.
- **The 63-bit `Int`.** Hashing and bit-twiddling packages may differ from GHC.
  This is expected until the opt-in 64-bit `Int` (stretch goal) exists. Record
  it rather than patching around it.
