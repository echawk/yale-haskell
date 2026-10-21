{-# LANGUAGE MagicHash, UnboxedTuples #-}
module Main (main) where
import qualified GHC.Exts as Exts
main :: IO ()
main = case Exts.timesWord2# (2 ^ 63) 6 of (# h, l #) -> print (h, l)
