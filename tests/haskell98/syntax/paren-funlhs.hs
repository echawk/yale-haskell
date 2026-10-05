-- Parenthesised function left-hand sides (H98 report 4.4.3):
--   funlhs -> var apat {apat} | pat varop pat | ( funlhs ) apat {apat}
module Main where

infixr 9 .:
infixl 5 <+>

(.:) :: (c -> d) -> (a -> b -> c) -> a -> b -> d
(f .: g) x y = f (g x y)

(<+>) :: (Int -> Int) -> (Int -> Int) -> Int -> Int
(f <+> g) x = f x + g x

-- `(add x) y' defines add with two arguments.
add :: Int -> Int -> Int
(add x) y = x + y

-- Nested parentheses, several clauses, and a backquoted operator.
compose3 :: (Int -> Int) -> (Int -> Int) -> Int -> Int -> Int
((f `compose3` g) x) y = f (g x) * y

op :: [Int] -> [Int] -> Int -> Int
([] `op` ys) n = n + length ys
((x:xs) `op` ys) n = x + (xs `op` ys) n

-- Ordinary pattern bindings still work.
(p, q) = (1 :: Int, 2 :: Int)
(r:_) = [3 :: Int]

result :: String
result = unlines
  [ show ((negate .: (+)) 3 4)
  , show (((* 2) <+> (+ 1)) 10)
  , show (add 3 4)
  , show (compose3 (+ 1) (* 3) 5 10)
  , show (([1, 2] `op` [7, 8, 9]) 100)
  , show (p + q + r)
  , show (local 4)
  ]
  where
    local n = (twice `with` n) 1
    (f `with` n) x = f n + x
    twice m = m * 2

main = appendChan stdout result abort done
