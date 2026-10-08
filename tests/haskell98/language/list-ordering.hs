-- Ord on lists is lexicographic with [] smallest (Haskell 98 Report,
-- section 6.1.3: lists are ordered as if derived from
-- data [a] = [] | a : [a]).  So a proper prefix sorts first.
module Main where
import Dialogue (stdout, appendChan, done, abort)

out :: String
out = unlines [ show ([] < [1 :: Int], [1] < [1, 2 :: Int], [2] < [1, 2 :: Int])
              , show ("ab" < "abc", "abc" <= "abd", "" < "a")
              , show (max "a" "", min "car" "cart") ]

main = appendChan stdout out abort done
