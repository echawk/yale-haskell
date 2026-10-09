module Main where

table :: [(Int, String)]
table = [(1, "one"), (2, "two"), (3, "three")]

-- a pattern guard, then a boolean guard falling through to the next equation
describe :: Int -> String
describe n
  | Just s <- lookup n table, length s > 3 = "long " ++ s
  | Just s <- lookup n table = "short " ++ s
describe n
  | even n = "even"
  | otherwise = "odd"

-- let in a guard, bindings seen by later quals and the rhs
classify :: Int -> String
classify x
  | let y = x * x, y > 50, (q, r) <- y `divMod` 7, r == 0 = "square " ++ show y ++ " = 7*" ++ show q
  | let y = x * x, y > 50 = "big " ++ show y
  | otherwise = "small"

-- in case alternatives, with nested constructor patterns
firstPos :: [Maybe Int] -> Int
firstPos ms = case ms of
  (m : rest) | Just v <- m, v > 0 -> v
             | otherwise -> firstPos rest
  [] -> 0

-- a lambda-free simple function where every guard can fail
safeHead :: [a] -> Maybe a
safeHead xs | (y:_) <- xs = Just y
safeHead _ = Nothing

-- falling off all guards of the only equation
partial :: Int -> Int
partial n | Just m <- lookup n [(1,10)] = m

-- polymorphic, with a where-bound function used in the guard
lookupBoth :: Eq k => k -> k -> [(k, v)] -> Maybe (v, v)
lookupBoth a b env
  | Just x <- look a, Just y <- look b = Just (x, y)
  | otherwise = Nothing
  where look k = lookup k env

-- irrefutable and lazy patterns in guards, and a binding shadowing an argument
shadow :: Int -> Int
shadow x | ~(a, b) <- (x, x + 1), x <- a + b = x

main :: IO ()
main = do
  mapM_ (putStrLn . describe) [1, 2, 3, 4, 5]
  mapM_ (putStrLn . classify) [3, 7, 8, 14]
  print (firstPos [Nothing, Just (-1), Just 5, Just 6])
  print (safeHead "abc", safeHead ([] :: [Int]))
  print (lookupBoth 1 3 table, lookupBoth 1 9 table)
  print (shadow 4)
  print (partial 1)
  print (partial 2)
