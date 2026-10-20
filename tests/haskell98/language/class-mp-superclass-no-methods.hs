{-# LANGUAGE MultiParamTypeClasses, FlexibleContexts, FlexibleInstances #-}
module Main (main) where
class Store f a where
  put :: a -> f a
class Store Maybe a => Unboxy a
instance Store Maybe Int where put = Just
instance Store Maybe [a] where put = Just
instance Unboxy Int
instance Unboxy a => Unboxy [a]
wrapU :: Unboxy a => a -> Maybe a
wrapU = put
main :: IO ()
main = print (wrapU (3 :: Int), wrapU [[1 :: Int]])
