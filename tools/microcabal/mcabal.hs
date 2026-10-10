-- mcabal: MicroCabal (ref/MicroCabal, `make ref`) run by Yale Haskell.
-- Its main module is MicroCabal.Main; this Main calls it.
--   bin/yale-haskell --haskell98 --modern-prelude tools/microcabal/mcabal.hs ARGS
module Main (main) where

import qualified MicroCabal.Main as M

main :: IO ()
main = M.main
