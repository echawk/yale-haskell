-- Overloading: methods dispatched on the result type, overloaded
-- numeric literals in expressions and patterns, a method used at two
-- types in one expression, and polymorphic functions with contexts.
module Main where
import Dialogue (stdout, appendChan, done, abort)

class Def a where
  def :: a

instance Def Int where
  def = 42

instance Def Bool where
  def = True

instance (Def a, Def b) => Def (a, b) where
  def = (def, def)

isZero :: (Eq a, Num a) => a -> Bool  -- Eq only for modern GHC; in H98 Num implies it
isZero 0 = True
isZero _ = False

double :: (Num a) => a -> a
double x = x + x

total :: (Num a) => [a] -> a
total = foldr (+) 0

out :: String
out = unlines
  [ show (def :: Int)
  , show (def :: (Bool, Int))
  , show (isZero (0 :: Int), isZero (0.0 :: Double), isZero (3 :: Integer))
  , show (double (3 :: Int), double (100000000000000000000 :: Integer))
  , show (total [1, 2, 3 :: Int] + length [def :: Bool])
  , show (truncate (double 1.25 :: Double) :: Int)
  ]

main = appendChan stdout out abort done
