-- Instances of a constructor class for partially applied type
-- constructors: a two-parameter data type and the function arrow.
module Main where

class Mappable f where
  over :: (a -> b) -> f a -> f b

data Pair c a = Pair c a
data Or e a   = Bad e | Good a

instance Mappable (Pair c) where
  over f (Pair c a) = Pair c (f a)

instance Mappable (Or e) where
  over _ (Bad e)  = Bad e
  over f (Good a) = Good (f a)

instance Mappable ((->) r) where
  over f g = f . g

showOr :: Or String Int -> String
showOr (Bad e)  = "bad " ++ e
showOr (Good a) = "good " ++ show a

out :: String
out = unlines [ case over (+ 1) (Pair 'k' (41 :: Int)) of Pair c a -> c : ' ' : show a
              , showOr (over (* 2) (Good 21)) ++ ", " ++ showOr (over (* 2) (Bad "no"))
              , show (over (* 3) (+ 1) (4 :: Int)) ]

main = appendChan stdout out abort done
