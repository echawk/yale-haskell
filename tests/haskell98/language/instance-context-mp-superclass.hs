{-# LANGUAGE MultiParamTypeClasses, FlexibleContexts, FlexibleInstances #-}
module Main (main) where
class Store f a where
  put :: a -> f a
class Store Maybe a => Unboxy a
instance Store Maybe Int where put = Just
instance Unboxy Int

newtype Id a = Id a
instance Store Maybe a => Store Maybe (Id a) where
  put (Id x) = fmap Id (put x)

class Pretty a where
  pretty :: a -> String
-- the instance context's superclass gives Store Maybe a
instance (Show a, Unboxy a) => Pretty (Id a) where
  pretty (Id x) = maybe "-" show (put x)
    where _ = ()

main :: IO ()
main = putStrLn (pretty (Id (5 :: Int)))
