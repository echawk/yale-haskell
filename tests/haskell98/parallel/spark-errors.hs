-- A spark whose evaluation fails is dropped; the error is raised where
-- the value is demanded (four capabilities, spark-errors.args).
module Main where

import Control.Parallel
import Control.Exception

main :: IO ()
main = do
  let bad = error "boom" :: Int
      good = sum [1 .. 1000 :: Int]
  r <- try (evaluate (bad `par` (good `pseq` (good + bad))))
  case r of
    Left e -> putStrLn ("caught: " ++ takeWhile (/= '\n') (show (e :: ErrorCall)))
    Right v -> print v
  print (good `par` good + 1)
