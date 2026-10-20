{-# LANGUAGE TypeOperators, ExplicitNamespaces #-}
module Main (main) where
import TypeOpExport (Pair(..), type (:!:), type (+++), mk)
f :: Int +++ Bool -> Int :!: Char
f (Left n) = mk n 'l'
f (Right _) = 0 :!: 'r'
main :: IO ()
main = print (f (Left 3), f (Right True))
