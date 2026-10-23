{-# LANGUAGE RankNTypes, ConstraintKinds #-}
module Main where
type FoldFn m a = Monoid m => (Int -> m) -> a -> m
type TravFn m a = (Applicative m, Monad m) => (Int -> m Int) -> a -> m a

foldL :: FoldFn m [Int]
foldL f xs = mconcat (map f xs)

travL :: TravFn m [Int]
travL f xs = traverse f xs

main :: IO ()
main = do
  putStrLn (foldL show [1,2,3])
  ys <- travL (\x -> return (x+1)) [1,2,3]
  print ys
