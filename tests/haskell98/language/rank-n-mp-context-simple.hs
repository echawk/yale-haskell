{-# LANGUAGE RankNTypes, MultiParamTypeClasses, FlexibleInstances #-}
class Conv a b where
  conv :: a -> b
instance Conv Int String where
  conv = show
data Chunk a = Chunk (forall b. Conv a b => a -> b)
useChunk :: Chunk Int -> String
useChunk (Chunk f) = f 5
main = putStrLn (useChunk (Chunk conv))
