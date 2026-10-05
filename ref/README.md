# Reference implementations (not part of this repository)

This directory holds local, untracked clones used as guides for the
Haskell 98 work.  Recreate them with `make ref` (or by hand):

| Directory        | Source                                                       | Use |
|------------------|--------------------------------------------------------------|-----|
| `hugs98/`        | https://github.com/augustss/hugs98-plus-Sep2006              | Reference H98 implementation.  `libraries/hugsbase/Hugs/Prelude.hs` is a single-file Prelude; `packages/haskell98`, `packages/base` hold the libraries; `src/parser.y` is the grammar. |
| `haskell-report/`| https://github.com/haskell/haskell-report (branch `h98`)     | The Haskell 98 Report.  `report/*.hs` is the Standard Prelude; `libraries/code/*.hs` the library reference code. |

Licensing: Hugs is BSD-style (`hugs98/License`; the Yale Haskell Group
is among its copyright holders) and the Report code may be copied with
its notice.  Code borrowed from either must keep its notice.  Do not
copy from nhc98 (its licence is copyleft-like).
