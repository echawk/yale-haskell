{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Pattern synonyms with view patterns, used in clauses, case
-- alternatives and do binds, here and from another module (pattern P
-- in its export list).
import PatSynViews

pattern Halves :: [a] -> [a] -> [a]
pattern Halves xs ys <- (\l -> splitAt (length l `div` 2) l -> (xs, ys))

f :: T -> [Int]
f (L xs) = xs
f (A n) = [n]

halves :: [Int] -> String
halves l = case l of
  Halves [] [] -> "empty"
  Halves a b | length a == length b -> "even " ++ show (a, b)
             | otherwise -> "odd " ++ show (a, b)

main :: IO ()
main = do
  print (f (L [1, 2, 3]), L [4, 5], f (A Two), f (N [7, 8]))
  print (case 2 :: Int of { Two -> "two"; _ -> "other" })
  mapM_ (putStrLn . halves) [[], [1, 2, 3, 4], [1, 2, 3]]
  print [n | Pos n <- [-3, 4 :: Int]]
  L ys <- return (N [9, 10])
  print ys
