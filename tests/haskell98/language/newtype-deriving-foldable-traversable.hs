{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- A newtype over another type deriving Functor and Foldable through it,
-- with a Traversable instance of its own (vector's Data.Vector.Strict).
newtype Strict a = Strict [a] deriving (Show, Functor, Foldable)

instance Traversable Strict where
  traverse f (Strict xs) = Strict <$> traverse f xs

main :: IO ()
main = do
  print (fmap (+ 1) (Strict [1, 2, 3 :: Int]), sum (Strict [4, 5 :: Int]))
  print (traverse (\x -> if x > 0 then Just x else Nothing) (Strict [1, 2 :: Int]))
