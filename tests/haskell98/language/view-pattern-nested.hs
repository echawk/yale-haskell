-- View patterns inside a view pattern's pattern (JHC's (fromPi -> (fromUnboxed
-- Tuple -> Just [s',x], [getType -> s'']))): the outer view first.
{-# LANGUAGE ViewPatterns #-}
module Main where
split :: Int -> (Int, [Int])
split n = (n * 2, [n, n + 1])

f :: Int -> String
f (split -> (succ -> a, [show -> s, _])) = show a ++ s
f _ = "none"

main = putStrLn (f 5)
