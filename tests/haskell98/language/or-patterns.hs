-- OrPatterns (GHC 9.12): (p1; p2) in clauses and case alternatives.
{-# LANGUAGE OrPatterns #-}
data C = R | G | B | K Int
f :: C -> Int
f (R; G) = 1
f (B; K 0; K 1) = 2
f _ = 3
g :: Maybe Int -> String
g x = case x of
  (Nothing; Just 0) -> "zeroish"
  Just n -> show n
main = print (map f [R, G, B, K 0, K 5], map g [Nothing, Just 0, Just 7])
