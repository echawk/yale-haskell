{-# LANGUAGE ViewPatterns #-}
data P = P Int [Int]

sub :: (Int -> Int -> Bool) -> P -> P -> Bool
sub f (P k xs) (toL -> ys) =
  kvSub
    && all (`elem` ys) xs
  where
    kvSub = k `elem` ys

toL :: P -> [Int]
toL (P k xs) = k : xs

main :: IO ()
main = print (sub (==) (P 1 [2]) (P 2 [1, 3]))
