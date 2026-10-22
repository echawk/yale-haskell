{-# LANGUAGE MagicHash #-}
module Main where
import GHC.Exts (Char (C#))
f :: Char -> Bool
f c = c == C# ('['#)
main = print (C# 'x'#, f '[')
