# Reference implementations (not part of this repository)

This directory holds local, untracked clones used as guides for the
Haskell 98 work.  Recreate them with `make ref` (or by hand):

| Directory        | Source                                                       | Use |
|------------------|--------------------------------------------------------------|-----|
| `hugs98/`        | https://github.com/augustss/hugs98-plus-Sep2006              | Reference H98 implementation.  `libraries/hugsbase/Hugs/Prelude.hs` is a single-file Prelude; `packages/haskell98`, `packages/base` hold the libraries; `src/parser.y` is the grammar. |
| `haskell-1.x/`   | https://www.haskell.org/definition/ (`make ref` fetches the files below) | Older Reports.  `haskell-report-1.2.*` and `haskell-report-1.3.*` (PostScript only, converted to `.pdf`/`.txt`); 1.4 language and library Reports as PostScript and HTML (`haskell-report-1.4-html/standard-prelude.html` is the 1.4 Prelude, `haskell-library-1.4-html/` the libraries).  `from12to13.html` and `from13to14.html` summarise the changes between versions.  The 1.3 *Library* Report is not on haskell.org; still to be found. |
| `ghc-3.02/`      | https://downloads.haskell.org/~ghc/3.02/ghc-3.02-src.tar.gz | GHC 3.02 (1998), a Haskell 1.4 implementation.  `ghc/lib/std/` holds its 1.4 Prelude (`Prel*.lhs`) and libraries.  For GHC 0.29 (Haskell 1.2) see the same server; no GHC 2.x (Haskell 1.3) source is published there. |
| `haskell-report/`| https://github.com/haskell/haskell-report (branch `h98`)     | The Haskell 98 Report.  `report/*.hs` is the Standard Prelude; `libraries/code/*.hs` the library reference code. |

Licensing: Hugs is BSD-style (`hugs98/License`; the Yale Haskell Group
is among its copyright holders) and the Report code may be copied with
its notice.  Code borrowed from either must keep its notice.  GHC 3.02 has no
licence file (only `(c) The GRASP/AQUA Project, Glasgow University`
headers), so read it for ideas but do not copy it; take code from the
Reports instead.  Do not
copy from nhc98 (its licence is copyleft-like).
