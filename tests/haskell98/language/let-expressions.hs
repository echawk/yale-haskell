-- let expressions: several bindings that refer to each other, nesting,
-- function bindings with guards, explicit braces and semicolons, and a
-- local type signature.
module Main where
import Dialogue (stdout, appendChan, done, abort)

hyp :: Int -> Int -> Int
hyp a b = let sq x = x * x
              total = sq a + sq b
          in total

nested :: Int
nested = let x = 1 in let y = x + 1 in let x = y * 10 in x + y

clamp :: Int -> Int
clamp n = let f k | k < 0     = 0
                  | k > 9     = 9
                  | otherwise = k
          in f n

braces :: Int
braces = let { a = 1; b = a + 2 ; c = b * b } in a + b + c

typed :: String
typed = let count :: [a] -> Int
            count = length
        in show (count "abc" + count [(), ()])

out :: String
out = unlines [ show (hyp 3 4), show nested
              , unwords (map (show . clamp) [-5, 4, 12])
              , show braces, typed ]

main = appendChan stdout out abort done
