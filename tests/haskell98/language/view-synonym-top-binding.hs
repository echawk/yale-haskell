-- A top-level pattern binding through a pattern synonym with a view
-- pattern (base64-bytestring's BS decodeFP _ = ...): its variables are
-- bound by a case on the value, lazily.
{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
data T = T Int [Int]
pattern P :: Int -> Int -> T
pattern P a n <- (view -> (a, n))
view :: T -> (Int, Int)
view (T a xs) = (a, length xs)
P first count = T 7 [1, 2, 3]
P lazyA _ = undefined
main :: IO ()
main = print (first, count) >> putStrLn "lazy ok"
