{-# LANGUAGE TemplateHaskell, QuasiQuotes #-}
module Main where
import TypeGen

both :: $(pairOf [t| Int |])
both = (1, 2)

f :: [ty|Int Bool|]
f n b = if b then print n else return ()

g :: a -> $(pairOf [t| Maybe Char |])
g _ = (Just 'x', Nothing)

main :: IO ()
main = do
  print both
  f 3 True
  print (g ())
