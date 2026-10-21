{-# LANGUAGE TypeFamilies, DataKinds, PolyKinds, TypeOperators, ConstraintKinds, KindSignatures, FlexibleContexts #-}
-- A constraint family in a signature's context (Agda's All p as): not
-- evaluated; the dictionaries it would give are given otherwise
module Main (main) where
import ConstraintFamilyContextA (All)

shown :: (All Show '[a, b], Show a, Show b) => a -> b -> String
shown x y = show x ++ show y

-- and in a nested context, C => D => t
twice :: All Show '[a] => Show a => a -> String
twice x = show x ++ show x

main :: IO ()
main = putStrLn (shown (1 :: Int) True) >> putStrLn (twice (7 :: Int))
