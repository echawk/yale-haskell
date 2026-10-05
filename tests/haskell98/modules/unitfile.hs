-- Imports ViaUnit, which is found through the unit file ViaUnit.hu next
-- to this file (the module itself lives in ViaUnitImpl.hs).
module Main where

import ViaUnit

main = appendChan stdout (viaUnit ++ "\n") abort done
