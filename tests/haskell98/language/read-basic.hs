-- read and reads at standard types, through an explicit type
-- (works through the Haskell 1.2 Text class today).
module Main where
import Dialogue (stdout, appendChan, done, abort)

total :: [Int] -> Int
total = sum

out :: String
out = unlines [ show (total (read "[1,2,3]"))
              , show ((read " ( 3 , True ) " :: (Int, Bool)) == (3, True))
              , show (read "-5" + (1 :: Int))
              , show (map fst (reads "12 rest" :: [(Int, String)]))
              , read "\"quoted\"" ]

main = appendChan stdout out abort done
