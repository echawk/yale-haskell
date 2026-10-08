module Main where

-- Writes many lines to a file, reads them back, and sums them, so that
-- stdout stays short.
main :: IO ()
main = do
  let n = 200000 :: Int
      path = "/tmp/yale-bench-ioloop.txt"
  writeFile path (unlines (map show [1 .. n]))
  s <- readFile path
  print (sum (map read (lines s) :: [Int]))
  mapM_ (\i -> if i `mod` 50000 == 0 then putStrLn (show i) else return ()) [1 .. n]
