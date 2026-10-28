-- View patterns as list and tuple elements, without their own parentheses
-- (JHC's let [fromHsTyVar -> Just classArg] = ..).
{-# LANGUAGE ViewPatterns #-}
module Main where
f :: [Int] -> (Int, Int)
f [succ -> a, (* 2) -> b] = (a, b)
f _ = (0, 0)
main = do
  let [show -> s, _] = [1, 2 :: Int]
      (x, negate -> y) = (3 :: Int, 4 :: Int)
  print (f [1, 5], s, x, y)
