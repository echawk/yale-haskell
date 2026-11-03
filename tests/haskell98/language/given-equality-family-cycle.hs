{-# LANGUAGE TypeFamilies, TypeOperators, FlexibleContexts, FlexibleInstances,
             ScopedTypeVariables, UndecidableInstances, FunctionalDependencies,
             RankNTypes, DeriveGeneric #-}
-- lens's Control.Lens.Tuple generic indexing (ix): the instance's given
-- equalities p ~ GT (GSize s) n and p ~ GT (GSize t) n, with GIxed's
-- superclass equalities, reduce GT (GSize t) n to GT (GSize s) n and back;
-- the type checker went round for ever
import GHC.Generics
import Data.Proxy
import Data.Functor.Identity

type Lens s t a b = forall f. Functor f => (a -> f b) -> s -> f t

data Z
data S a
data T
data F

type family GSize (f :: * -> *)
type instance GSize U1 = Z
type instance GSize (K1 i c) = S Z
type instance GSize (M1 i c f) = GSize f
type instance GSize (a :*: b) = Add (GSize a) (GSize b)

type family Add x y
type instance Add Z y = y
type instance Add (S x) y = S (Add x y)

type family Subtract x y
type instance Subtract Z x = x
type instance Subtract (S x) (S y) = Subtract x y

type family GT x y
type instance GT Z x = F
type instance GT (S x) Z = T
type instance GT (S x) (S y) = GT x y

class GIxed n s t a b | n s -> a, n t -> b, n s b -> t, n t a -> s where
  gix :: f n -> Lens (s x) (t x) a b

instance GIxed Z (K1 i a) (K1 i b) a b where
  gix _ f (K1 a) = fmap K1 (f a)

instance GIxed n s t a b => GIxed n (M1 i c s) (M1 i c t) a b where
  gix n f (M1 s) = fmap M1 (gix n f s)

instance (p ~ GT (GSize s) n,
          p ~ GT (GSize t) n,
          GIxed' p n s s' t t' a b)
      => GIxed n (s :*: s') (t :*: t') a b where
  gix = gix' (Proxy :: Proxy p)

class (p ~ GT (GSize s) n,
       p ~ GT (GSize t) n)
   => GIxed' p n s s' t t' a b | p n s s' -> a
                               , p n t t' -> b
                               , p n s s' b -> t t'
                               , p n t t' a -> s s' where
  gix' :: f p -> g n -> Lens ((s :*: s') x) ((t :*: t') x) a b

instance (GT (GSize s) n ~ T,
          GT (GSize t) n ~ T,
          GIxed n s t a b)
      => GIxed' T n s s' t s' a b where
  gix' _ n f (s :*: s') = fmap (:*: s') (gix n f s)

instance (GT (GSize s) n ~ F,
          n' ~ Subtract (GSize s) n,
          GIxed n' s' t' a b)
      => GIxed' F n s s' s t' a b where
  gix' _ _ f (s :*: s') = fmap (s :*:) (gix (Proxy :: Proxy n') f s')

ix :: (Generic s, Generic t, GIxed n (Rep s) (Rep t) a b) => f n -> Lens s t a b
ix n f = fmap to . gix n f . from

data P = P Int Char Bool deriving (Show, Generic)

main :: IO ()
main = do
  print (runIdentity (ix (Proxy :: Proxy (S Z)) (\c -> Identity (succ c)) (P 1 'a' True)) :: P)
  print (runIdentity (ix (Proxy :: Proxy Z) (\n -> Identity (n * 10)) (P 4 'x' False)) :: P)
  print (runIdentity (ix (Proxy :: Proxy (S (S Z))) (Identity . not) (P 0 'q' False)) :: P)
