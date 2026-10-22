{-# LANGUAGE DeriveFunctor, DeriveFoldable, DeriveTraversable #-}
-- A field that is a tuple with the variable in several components
-- (Agda's ListT: m (Maybe (a, ListT m a)))
module Main (main) where

data T a = T Int (a, [a], Bool) (Maybe (a, Int)) deriving (Show, Functor, Foldable, Traversable)

main :: IO ()
main = do
  let t = T 0 (1, [2, 3], True) (Just (4, 5)) :: T Int
  print (fmap (* 10) t)
  print (sum t, length t)
  print (traverse (\x -> if x > 0 then Just (x + 1) else Nothing) t)
