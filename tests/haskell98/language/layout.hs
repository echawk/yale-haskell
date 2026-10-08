{- The layout rule: implicit blocks for where, let and case, explicit
   braces inside an implicit block, the parse-error(t) rule that closes
   a let block before 'in', and {- nested -} comments. -}
module Main where
import Dialogue (stdout, appendChan, done, abort)

f :: Int -> Int
f x = case x of
        0 -> 100
        n | n < 0 -> g n
          | otherwise ->
              let y = n * 2
                  z = y + 1
              in z
  where
    g m = negate m

h :: Int -> Int
h x = case x of { 1 -> 10 ; 2 -> 20 ; _ -> 0 }

oneLine :: Int
oneLine = let a = 3 in a * a       -- 'in' closes the implicit let block

pairs :: [(Int, Int)]
pairs = [ (a, b)
        | a <- [1, 2]
        , b <- [a .. 2]
        ]

out :: String
out = unlines [ unwords (map (show . f) [0, -4, 5])
              , unwords (map (show . h) [1, 2, 3])
              , show oneLine
              , show (length pairs) ]

main = appendChan stdout out abort done
