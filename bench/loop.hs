module Main where

-- Tight strict loop over five Int accumulators (seq and mod): measures
-- call and arithmetic code for strict Int code, the case representation
-- types and self-local calls are for.
loop :: Int -> Int -> Int -> Int -> Int -> Int
loop 0 a b c d = a + b + c + d
loop n a b c d = a `seq` b `seq` c `seq` d `seq`
  loop (n - 1) ((a + b) `mod` 1024) ((b + c) `mod` 1024) ((c + d) `mod` 1024) ((d + a) `mod` 1024)
main = print (loop 300000000 1 2 3 4)
