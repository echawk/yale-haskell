-- Qualified names (Haskell 98 section 5.5.1): Prelude.map,
-- qualified operators in sections and backquotes, and Main.f for a
-- top-level name shadowed by a local one.
module Main where

f :: Int
f = 10

g :: Int -> Int
g f = f + Main.f

out :: String
out = unlines [ unwords (Prelude.map show (Prelude.filter even [1 .. 10 :: Int]))
              , show (Prelude.foldr (Prelude.+) 0 [1, 2, 3 :: Int])
              , show (17 `Prelude.div` 5 :: Int, (Prelude.* 2) (21 :: Int))
              , show (g 1) ]

main = appendChan stdout out abort done
