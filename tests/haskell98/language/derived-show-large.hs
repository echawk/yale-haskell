-- Deriving Show alone for a type with more than 6 constructors (whose
-- derived Read is split into separate functions) must not require Read
-- of the field types; deriving both still round-trips.
module Main where

data Range = R0 Int | R1 Int | R2 Int | R3 Int | R4 Int | R5 Int
           | ROr Range Range
  deriving (Show)

data Value = VRange Range | VPkgs [(String, Maybe Range)]
  deriving (Show)

data Both = B0 | B1 Int | B2 Int | B3 Int | B4 Int | B5 Int | B6 Both Both
  deriving (Show, Read, Eq)

main :: IO ()
main = do
  print (VRange (ROr (R0 1) (R5 2)))
  print (VPkgs [("base", Just (R3 4)), ("x", Nothing)])
  let b = B6 (B1 1) (B6 B0 (B5 (-5)))
  print b
  print ((read (show b) :: Both) == b)
