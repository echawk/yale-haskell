-- mcabal: MicroCabal (the submodule tools/microcabal/MicroCabal) run by Yale Haskell.
-- Its main module is MicroCabal.Main; this Main calls it.
--   bin/yale-haskell --haskell98 --modern-prelude -i tools/microcabal/MicroCabal/src \
--     tools/microcabal/mcabal.hs ARGS     (tools/microcabal/mcabal does this)
module Main (main) where

import qualified MicroCabal.Main as M

main :: IO ()
main = M.main
