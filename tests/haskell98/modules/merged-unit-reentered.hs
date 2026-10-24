-- A cycle reached again through a file merged into a unit still loading
-- (B, merged into A's unit, imported by C): only that unit's cycle is
-- merged, not every unit being loaded (Agda's Syntax.Scope.Flat).
module Main where
import MergedCycX
import MergedCycB
import MergedCycC
main = print (x, b, c)
