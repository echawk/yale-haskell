{- This is a simple merge sort -}

module Main where  -- was "module Merge"; renamed so it runs as a program
                
merge :: [Int] -> [Int] -> [Int]
merge [] x = x  
merge x [] = x
merge l1@(a:b) l2@(c:d) | a < c     = a:(merge b l2)
			| otherwise = c:(merge l1 d)

half [] = []
half [x] = [x]
half (x:y:z) = x:r where r = half z

sort [] = []
sort [x] = [x]
sort l = merge (sort odds) (sort evens) where
	     odds = half l
	     evens = half (tail l)

main =
  appendChan stdout "Enter a list of integers separated by \",\"\n" abort $
  readChan stdin abort $ \ input ->
  appendChan stdout 
      (show (sort (read ("[" ++ (head (lines input)) ++ "]"))))
      abort done
