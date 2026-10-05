-- A chain of three modules found without .hu files:
-- Main -> ChainB -> ChainC.  Main also imports ChainC directly.
module Main where

import ChainB
import ChainC (c)

main = appendChan stdout (show (b, c) ++ "\n") abort done
