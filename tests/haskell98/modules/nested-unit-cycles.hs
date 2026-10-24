-- A cycle B, C merged into one unit, then into A's: C is A's unit too,
-- not compiled again (Agda's Syntax.Scope.Flat).
module Main where
import NestCycA
import NestCycC
import NestCycB
main = print (a, c, bc)
