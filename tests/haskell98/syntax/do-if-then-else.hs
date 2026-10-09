-- Haskell 2010 DoAndIfThenElse: then and else at the do block's
-- indentation; and the empty context () => (Haskell 98 4.1.3).
module Main where

f :: () => Int -> Int
f x = x + 1

main :: IO ()
main = do
  let x = f 2
  if x > 2
  then putStrLn "big"
  else putStrLn "small"
  r <- if even x
       then return "even"
       else return "odd"
  putStrLn r
