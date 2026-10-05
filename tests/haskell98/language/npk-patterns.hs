-- n+k patterns (Haskell 98 section 3.17.2): they match only when the
-- argument is >= k, and bind n to the argument minus k.
module Main where

fact :: Integer -> Integer
fact 0       = 1
fact (n + 1) = (n + 1) * fact n

pred2 :: Int -> Int
pred2 (n + 2) = n
pred2 _       = -1

halve :: Int -> Int
halve x = case x of
            n + 2 -> 1 + halve n
            _     -> 0

out :: String
out = unlines [ show (fact 20)
              , unwords (map (show . pred2) [0, 1, 2, 5])
              , show (halve 9) ]

main = appendChan stdout out abort done
