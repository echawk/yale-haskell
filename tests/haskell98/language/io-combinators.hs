-- IO without do: >>=, >>, =<<, return, sequence_, mapM_, mapM and
-- print; main may have type IO t for any t (Haskell 98 section 5).
module Main where

main :: IO Int
main =
  putStr "a" >> putStrLn "b" >>
  sequence_ [putStr "x", putStr "y", putStrLn "z"] >>
  mapM_ print [1, 2, 3 :: Int] >>
  mapM (\x -> return (x * 2)) [1, 2, 3 :: Int] >>= \ys ->
  print (sum ys) >>
  (putStrLn =<< return "via =<<") >>
  return 42
