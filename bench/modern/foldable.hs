-- Derived Functor, Foldable and Traversable on a rose tree of 10^6
-- nodes: fmap, sum, maximum, length, foldr and traverse in Maybe.
{-# LANGUAGE DeriveFunctor, DeriveFoldable, DeriveTraversable #-}
data Rose a = Rose a [Rose a] deriving (Functor, Foldable, Traversable)

build :: Int -> Int -> Rose Int
build d x
  | d == 0 = Rose x []
  | otherwise = Rose x [build (d - 1) (x * 3 + i) | i <- [0 .. 2]]

main :: IO ()
main = do
  let t = build 12 1
      t2 = fmap (\x -> x `mod` 1000) t
  print (length t, sum t2, maximum t2)
  print (foldr (\x n -> if even x then n + 1 else n) (0 :: Int) t2)
  print (fmap sum (traverse (\x -> if x >= 0 then Just (x + 1) else Nothing) t2))
