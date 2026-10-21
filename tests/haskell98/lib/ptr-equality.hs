{-# LANGUAGE MagicHash #-}
module Main (main) where
import GHC.Exts (reallyUnsafePtrEquality#, isTrue#, Constraint)
main :: IO ()
main = do
  let xs = [1, 2, 3 :: Int]
  print (isTrue# (reallyUnsafePtrEquality# xs xs), isTrue# (reallyUnsafePtrEquality# xs (map id xs)))
