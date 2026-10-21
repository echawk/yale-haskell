{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
module Main (main) where

class Conv a b where
  conv :: a -> b
instance Conv [Int] Bool where
  conv = null
instance Conv Int Bool where
  conv = (> 0)

class Step t u where
  step :: Conv t u => t -> u -> (u, u)

instance Step Int Bool where
  step x y = (conv x, y)

instance Step t u => Step [t] u where
  step _ y = (y, y)

main :: IO ()
main = print (step (3 :: Int) False, step [1 :: Int] True)
