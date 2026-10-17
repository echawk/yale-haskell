-- Data.Bitraversable (base): traversals of the two parameters of a type.
module Data.Bitraversable (
    Bitraversable(bitraverse), bisequenceA, bisequence, bimapM, bifor,
    bimapDefault, bifoldMapDefault
  ) where

import PreludeModern
import Data.Bifunctor (Bifunctor)
import Data.Bifoldable (Bifoldable)
import Data.Functor.Const (Const(Const, getConst))
import Data.Functor.Identity (Identity(Identity, runIdentity))

class (Bifunctor t, Bifoldable t) => Bitraversable t where
  bitraverse :: Applicative f => (a -> f c) -> (b -> f d) -> t a b -> f (t c d)

instance Bitraversable (,) where
  bitraverse f g (a, b) = (,) <$> f a <*> g b

instance Bitraversable ((,,) x) where
  bitraverse f g (x, a, b) = (,,) x <$> f a <*> g b

instance Bitraversable ((,,,) x y) where
  bitraverse f g (x, y, a, b) = (,,,) x y <$> f a <*> g b

instance Bitraversable Either where
  bitraverse f _ (Left a) = Left <$> f a
  bitraverse _ g (Right b) = Right <$> g b

instance Bitraversable Const where
  bitraverse f _ (Const a) = Const <$> f a

bisequenceA :: (Bitraversable t, Applicative f) => t (f a) (f b) -> f (t a b)
bisequenceA = bitraverse id id

bisequence :: (Bitraversable t, Applicative f) => t (f a) (f b) -> f (t a b)
bisequence = bisequenceA

bimapM :: (Bitraversable t, Applicative f) => (a -> f c) -> (b -> f d) -> t a b -> f (t c d)
bimapM = bitraverse

bifor :: (Bitraversable t, Applicative f) => t a b -> (a -> f c) -> (b -> f d) -> f (t c d)
bifor t f g = bitraverse f g t

bimapDefault :: Bitraversable t => (a -> b) -> (c -> d) -> t a c -> t b d
bimapDefault f g = runIdentity . bitraverse (Identity . f) (Identity . g)

bifoldMapDefault :: (Bitraversable t, Monoid m) => (a -> m) -> (b -> m) -> t a b -> m
bifoldMapDefault f g = getConst . bitraverse (Const . f) (Const . g)
