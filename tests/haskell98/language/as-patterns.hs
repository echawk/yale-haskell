-- As-patterns, including nested ones and one combined with ~.
module Main where

dupHead :: String -> String
dupHead s@(c:_) = c : s
dupHead []      = []

-- Remove adjacent duplicates.
compress :: [Int] -> [Int]
compress (x : rest@(y : _)) | x == y    = compress rest
                            | otherwise = x : compress rest
compress xs = xs

firstTwo :: [[Int]] -> String
firstTwo all@(xs@(a:_) : _) = show (length all) ++ " " ++ show (length xs) ++ " " ++ show a
firstTwo _                  = "none"

lazyAs :: (Int, Int) -> Int
lazyAs p@(~(a, _)) = 5

out :: String
out = unlines [ dupHead "abc"
              , unwords (map show (compress [1,1,2,3,3,3,1]))
              , firstTwo [[7,8,9],[1]]
              , show (lazyAs (error "never forced")) ]

main = appendChan stdout out abort done
