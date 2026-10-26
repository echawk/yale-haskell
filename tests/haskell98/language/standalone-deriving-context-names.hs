-- A standalone deriving's declared context names the head's variables,
-- not the data type's (bifunctors' Sum: Functor (f a) for data Sum p q a
-- b), and one swapped.
{-# LANGUAGE StandaloneDeriving, DeriveTraversable, FlexibleContexts, UndecidableInstances #-}
data Sum p q a b = L2 (p a b) | R2 (q a b)
deriving instance (Functor (f a), Functor (g a)) => Functor (Sum f g a)
deriving instance (Foldable (f a), Foldable (g a)) => Foldable (Sum f g a)
deriving instance (Traversable (f a), Traversable (g a)) => Traversable (Sum f g a)
main1 = print (sum (L2 (Right 3) :: Sum Either Either () Int))
data Two p q a = One (p a) | Other (q a)
deriving instance (Show (q a), Show (p a)) => Show (Two q p a)
main = do
  main1
  print (One (Just 'x') :: Two Maybe [] Char)
  print (Other "yz" :: Two Maybe [] Char)
