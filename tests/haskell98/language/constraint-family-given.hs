{-# LANGUAGE TypeFamilies, DataKinds, PolyKinds, TypeOperators, ConstraintKinds, KindSignatures, FlexibleContexts #-}
module Main (main) where
import Data.Kind (Constraint)

type family All (p :: k -> Constraint) (as :: [k]) :: Constraint where
  All p '[]       = ()
  All p (a ': as) = (p a, All p as)

showBoth :: All Show '[a, b] => a -> b -> String
showBoth x y = show x ++ "," ++ show y

main :: IO ()
main = putStrLn (showBoth (1 :: Int) True)
