-- Qualified names across modules (H98 5.3, 5.5): import qualified ... as,
-- qualified constructors in expressions and patterns, qualified operators
-- keep their fixity, a name exported by two modules is usable through
-- either qualifier, and `.' without spaces is still composition after a
-- lower-case name (Just.negate would be a qualified name, as in H98).
module Main where

import qualified QualA as A
import QualA (T(Leaf))
import qualified QualB

depth :: A.T -> Int
depth A.Leaf = 0
depth (A.Node l _ r) = 1 + max (depth l) (depth r)

data Colour = Red | Green | Blue deriving (Show, Enum)

main = do
  let t = A.Node (A.Node Leaf 1 Leaf) 2 Leaf
  print (A.size t, depth t)
  print (1 A.<+> 2 A.<+> 3, (A.<+> 5) 4, 2 `Prelude.max` 9)
  putStrLn A.shared
  putStrLn QualB.shared
  print ((show.length) "abc", (Just . negate) 3, [Red ..], [Red..])
  print (Main.depth Leaf, Prelude.length [Red, Blue])
