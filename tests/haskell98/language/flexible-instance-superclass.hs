{-# LANGUAGE FlexibleInstances #-}
newtype W s = W s
instance Semigroup (W [Int]) where W a <> W b = W (a ++ b)
instance Semigroup (W String) where W a <> W b = W (b ++ a)
instance Monoid (W [Int]) where mempty = W [0]
instance Monoid (W String) where mempty = W "e"
unW :: W s -> s
unW (W s) = s
main :: IO ()
main = print (unW (mconcat [W [1], W [2 :: Int]]), unW (mconcat [W "a", W "b"]))
