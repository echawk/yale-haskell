{-# LANGUAGE DerivingVia, StandaloneDeriving #-}
-- deriving via T instance ctx => C (D a): the declared context
module Main (main) where

newtype Shown a = Shown a

class Describe a where
  describe :: a -> String

instance (Show a, Eq a) => Describe (Shown a) where
  describe (Shown x) = show x ++ (if x == x then "" else "?")

newtype Box a = Box a

deriving via (Shown a) instance (Show a, Eq a) => Describe (Box a)

main :: IO ()
main = putStrLn (describe (Box (3 :: Int)))
