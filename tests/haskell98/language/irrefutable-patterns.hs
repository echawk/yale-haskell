-- Irrefutable (lazy) patterns, and the laziness of let/where pattern
-- bindings: the match is only forced when a variable is used.
module Main where
import Dialogue (stdout, appendChan, done, abort)

lazyArg :: (Int, Int) -> Int
lazyArg ~(a, b) = 1

-- Without the ~ this would loop on an infinite list.
partition' :: (a -> Bool) -> [a] -> ([a], [a])
partition' p = foldr step ([], [])
  where step x ~(ys, ns) | p x       = (x : ys, ns)
                         | otherwise = (ys, x : ns)

lazyLet :: Int
lazyLet = let (a, b) = error "never forced" in 7

lazyWhere :: Int
lazyWhere = 8 where [x] = [1, 2, 3]

lambdaLazy :: [Int] -> Int
lambdaLazy = \ ~(x:_) -> 0

out :: String
out = unlines [ show (lazyArg (error "never forced"))
              , unwords (map show (take 4 (fst (partition' even [1..]))))
              , show lazyLet
              , show lazyWhere
              , show (lambdaLazy []) ]

main = appendChan stdout out abort done
