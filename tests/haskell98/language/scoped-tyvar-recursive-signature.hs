{-# LANGUAGE RankNTypes, ScopedTypeVariables #-}
-- A local signature mentioning a scoped type variable still generalizes its own, so a recursive use passed as a rank-2 argument is polymorphic
class C a where
  q :: (forall d. C d => d -> u) -> a -> [u]
instance C Int where q _ _ = []
instance C a => C [a] where q f xs = map f xs

f4 :: forall r. (r -> r -> r) -> (forall a. C a => a -> r) -> (forall a. C a => a -> r)
f4 k f = go where
  go :: forall a. C a => a -> r
  go x = foldl k (f x) (q go x)

main :: IO ()
main = print (f4 (+) (const 1) [[1, 2 :: Int], [3]])
