{-# LANGUAGE RebindableSyntax #-}
-- RebindableSyntax: if-then-else is the ifThenElse in scope
module Main (main) where
import Prelude

data Tri = Yes | No | Maybe'

class IsBool b where
  ifThenElse :: b -> a -> a -> a

instance IsBool Bool where
  ifThenElse c t e = case c of { True -> t; False -> e }

instance IsBool Tri where
  ifThenElse Yes t _ = t
  ifThenElse _ _ e = e

main :: IO ()
main = do
  putStrLn (if Yes then "yes" else "no")
  putStrLn (if Maybe' then "yes" else "no")
  print (if 1 < (2 :: Int) then 'a' else 'b')
