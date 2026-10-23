{-# LANGUAGE ViewPatterns #-}
module Main where
main :: IO ()
main = do
  (length -> n) <- return "hello"
  print n
  print [ x | (even -> True, x) <- zip [1 :: Int ..] "abcd" ]
  r <- return [ y | Just (succ -> y) <- [Just 1, Nothing, Just (5 :: Int)] ]
  print r
