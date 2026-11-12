# YHS-0.1 — Fix CI

- **Status:** review
- **Branch:** ticket/YHS-0.1-fix-ci
- **Builder:** Claude Sonnet 5.5
- **Date:** 2026-11-12

## What changed
- `.github/workflows/ci.yml`: submodule checkout; pinned SBCL 2.6.10 (Linux: official binary tarball; macOS: Homebrew bottle with a version assertion); ocicl 2.20.0 installed (Linux release tarball, macOS brew); `ocicl/` cached on `hashFiles('ocicl.csv')` per OS; `make deps` step before `make`; SBCL version printed and checked.
- `doc/harness/TICKETS.md`: status.

## Failure cause (settles roadmap §3 and §6.1 "verify")
Read-only `gh run view 43165571879 -R echawk/yale-haskell --log-failed` (latest run, 2026-11-12). Both runners fail in the `Build` step at `haskell98-image` (`tools/build/image.lisp`, ASDF `make :yale-haskell/executable`: "unhandled condition in --disable-debugger mode"); the first lines of the condition are cut off in the log. Then every test exits 127 (no executable). Root cause: `ocicl/` is gitignored and `ci.yml` never ran `ocicl install`, so `image.lisp` (source registry tree `ocicl/`) cannot find clingon, cffi etc. That the missing libraries are the exact condition text is inferred, not seen. Ubuntu also ran `SBCL 2.2.9.debian` (log, "SBCL version" step) while the code is built for 2.6; the pinned version removes that second risk. macOS used brew SBCL (unpinned).

## Acceptance criteria
| # | Criterion | Met? | Evidence |
|---|---|---|---|
| 1 | Cause identified from failed-run logs and written here | yes | section above |
| 2 | ci.yml pins SBCL 2.6.x both runners, installs ocicl, `ocicl install`, caches on csv hash, submodules, prints version | yes (macOS pin = brew bottle + version assertion; SBCL has no macOS binary for 2.6.10, checked on SourceForge) | `.github/workflows/ci.yml` |
| 3 | Shell steps run locally on a clean clone | partly | macOS commands run (below). Linux-only steps (tarball SBCL install, ocicl linux tarball) not run: no Linux host. URLs checked: SBCL tarball returns 200 (13.3 MB), ocicl v2.20.0 release lists `ocicl-2.20.0-linux-amd64.tar.gz`. The tarball's internal layout (binary name `ocicl` found with `find`) is unverified. |
| 4 | CI green confirmed after human push | pending | human must push `ng` |

## How I tested
```sh
git clone . $S/clone && cd $S/clone && git submodule update --init
export YALE_HASKELL_CACHE_DIR=$S/cache
ocicl version                      # 2.20.0
nice -n 19 lockf -k $S/heavy.lock tools/bound 300 sh -c 'make deps && make HEAP_MB=8192'   # Built build/sbcl/haskell98/yale-haskell (16 s)
tools/bound 600 make test HEAP_MB=8192   # 925 passed, 0 failed, 0 expected failures, 0 unexpected passes
```
Local SBCL is 2.6.10. Haskell 1.2 suite not run: no compiler code changed.

## Environment notes
Workflow YAML was not linted with a tool (no PyYAML locally). The cold ocicl download on a clean clone worked over the network.

## Deviations from the roadmap
macOS pin is via Homebrew (version asserted, fails if brew moves past 2.6.10). Human may prefer a source build (open decision §10.1).

## North-star hooks
None affected.

## Known gaps / follow-ups
- If the push shows Linux failures (tarball layout, `INSTALL_ROOT`, `SBCL_HOME`), open YHS-0.1a.
- CI should call `scripts/check.sh` after YHS-0.3.

## Questions for the reviewer
- Approve the macOS brew-with-assertion method, or require source build?
