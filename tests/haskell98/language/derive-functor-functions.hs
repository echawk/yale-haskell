{-# LANGUAGE RankNTypes, DeriveFunctor #-}
-- Derived Functor over function types and polytypes (profunctors' Bar,
-- Bazaar, Baz).
module Main where

data F r a = F (r -> a) (Int -> Maybe a) (r -> Int -> [a]) Int
  deriving Functor

newtype Reader r a = Reader { runReader :: r -> a } deriving Functor

-- a in a function's argument's argument: covariant
newtype Bar t b a = Bar { runBar :: (a -> b) -> t } deriving Functor

newtype Bazaar a b t = Bazaar { runBazaar :: forall f. Applicative f => (a -> f b) -> f t }
  deriving Functor

newtype Baz t b a = Baz { runBaz :: forall f. Applicative f => (a -> f b) -> f t }
  deriving Functor

main :: IO ()
main = do
  case fmap (* 10) (F (+ 1) Just (\r n -> [r, n]) 7) of
    F g h k n -> print (g 1, h 2, k 3 4, n)
  print (runReader (fmap show (Reader (* 2))) (21 :: Int))
  print (runBar (fmap show (Bar (\k -> k (41 :: Int)))) length)
  print (runBazaar (fmap length (Bazaar (\k -> k 'x'))) (\c -> Just [c, c]))
  print (runBaz (fmap (+ 1) (Baz (\k -> k (1 :: Int)))) (\n -> [n, n * 10]))
