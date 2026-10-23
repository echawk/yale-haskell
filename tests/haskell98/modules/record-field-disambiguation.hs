module Main where
import qualified RecFldA as A
import RecFldI
import qualified RecFldB as G

f :: A.Conflict -> Int
f A.LitConflict { litType = a, litLeft = l } = a + l

main :: IO ()
main = do
  print (A.Clause { clauseLHS = 1, clauseCatchall = True })
  print (f (A.LitConflict 2 3), litType 1)
  print (G.defaultParams { G.level = 1, G.strategy = 2 })
