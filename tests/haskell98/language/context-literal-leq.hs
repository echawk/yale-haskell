-- a type-level literal on the left of <= in a context (random's 1 <= SeedSize g)
{-# LANGUAGE DataKinds, TypeOperators, KindSignatures #-}
import GHC.TypeLits
import Data.Proxy

class (KnownNat (S g), 1 <= S g) => C g where
  type S g :: Nat

main :: IO ()
main = putStrLn "ok"
