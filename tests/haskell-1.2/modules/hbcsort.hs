-- An explicit .hu file (hbcsort.hu) naming a library unit in a
-- subdirectory of $HASKELL_LIBRARY still works alongside the automatic
-- lookup, which has nothing to find for QSort here.
module Main where

import QSort

main = appendChan stdout (show (sort [3,1,4,1,5,9,2,6 :: Int]) ++ "\n") abort done
