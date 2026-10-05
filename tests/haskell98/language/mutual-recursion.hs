-- Mutually recursive functions (top level and local) and mutually
-- recursive data types.
module Main where

isEven, isOdd :: Int -> Bool
isEven 0 = True
isEven n = isOdd (n - 1)
isOdd 0  = False
isOdd n  = isEven (n - 1)

data Rose  = Rose Int Forest
data Forest = Empty | Trees Rose Forest

sumRose :: Rose -> Int
sumRose (Rose n f) = n + sumForest f

sumForest :: Forest -> Int
sumForest Empty       = 0
sumForest (Trees r f) = sumRose r + sumForest f

rose :: Rose
rose = Rose 1 (Trees (Rose 2 Empty) (Trees (Rose 3 (Trees (Rose 4 Empty) Empty)) Empty))

-- Local mutual recursion: alternate between two states.
alternate :: Int -> String
alternate n = ping n
  where ping 0 = ""
        ping k = 'a' : pong (k - 1)
        pong 0 = ""
        pong k = 'b' : ping (k - 1)

out :: String
out = unlines [ show (isEven 10, isOdd 7, isEven 3)
              , show (sumRose rose)
              , alternate 7 ]

main = appendChan stdout out abort done
