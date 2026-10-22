{-# LANGUAGE MultiWayIf #-}
-- MultiWayIf's alternatives are a layout block: the enclosing guard's
-- | otherwise, left of them, is not theirs
module Main (main) where

classify :: Int -> Bool -> String
classify k flag
  | flag = if
      | k == 0    -> "zero"
      | otherwise -> "nonzero"
  | otherwise = if | k < 0 -> "neg" | otherwise -> "pos"

main :: IO ()
main = mapM_ putStrLn [classify 0 True, classify 3 True, classify (-1) False, classify 2 False]
