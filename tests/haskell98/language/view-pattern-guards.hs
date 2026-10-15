-- A view pattern with several guards: each guard sees its variables,
-- and when all fail the next clause is tried.
{-# LANGUAGE ViewPatterns #-}
f :: [Int] -> Int
f (length -> n) | n > 2 = 1
                | n == 2 = 2
f _ = 0
main = print (map f [[1], [1, 2], [1, 2, 3]])
