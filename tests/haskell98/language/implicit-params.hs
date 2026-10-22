{-# LANGUAGE ImplicitParams #-}
module Main where
f :: (?cutoff :: Int) => Int -> Int
f n = n + ?cutoff
g :: (?cutoff :: Int, Show a) => a -> String
g x = show x ++ show (f 1)
h :: Int -> String
h c = let ?cutoff = c in g True
k :: Int -> IO ()
k c = do
  let ?cutoff = c * 10
  print (f 2)
  let ?cutoff = 7
  print (?cutoff + f 0)
main = putStrLn (h 5) >> k 3
