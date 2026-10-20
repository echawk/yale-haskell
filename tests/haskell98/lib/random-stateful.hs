{-# LANGUAGE MultiParamTypeClasses, FlexibleContexts #-}
import System.Random
import System.Random.Stateful
import Data.Word (Word64)

data Coin = H | T deriving Show
instance Uniform Coin where
  uniformM g = do { b <- uniformM g; return (if b then H else T) }

main = do
  let g = mkStdGen 42
      (xs, _) = runStateGen g (\s -> mapM (\_ -> uniformRM (1, 6 :: Int) s) [1 .. 20 :: Int])
  print (all (\x -> x >= 1 && x <= 6) xs, length xs)
  let (d, _) = uniformR (0.5, 1.5 :: Double) g
  print (d >= 0.5 && d <= 1.5)
  let (c, _) = uniform g :: (Coin, StdGen)
      (w, _) = uniform g :: (Word64, StdGen)
  print (case c of { H -> True; T -> True }, w == w)
  print (fst (uniformR (10, 10 :: Integer) g), fst (uniformR ('a', 'a') g))
