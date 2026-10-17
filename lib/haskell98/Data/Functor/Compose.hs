-- Data.Functor.Compose (base): the composition of two functors.
module Data.Functor.Compose (Compose(Compose, getCompose)) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Functor.Classes

infixr 9 `Compose`

newtype Compose f g a = Compose { getCompose :: f (g a) }

instance (Eq1 f, Eq1 g) => Eq1 (Compose f g) where
  liftEq eq (Compose x) (Compose y) = liftEq (liftEq eq) x y

instance (Ord1 f, Ord1 g) => Ord1 (Compose f g) where
  liftCompare cmp (Compose x) (Compose y) = liftCompare (liftCompare cmp) x y

instance (Show1 f, Show1 g) => Show1 (Compose f g) where
  liftShowsPrec sp sl d (Compose x) =
    showsUnaryWith (liftShowsPrec sp' sl') "Compose" d x
    where sp' = liftShowsPrec sp sl
          sl' = liftShowList sp sl

instance (Eq1 f, Eq1 g, Eq a) => Eq (Compose f g a) where
  (==) = eq1

instance (Ord1 f, Ord1 g, Ord a) => Ord (Compose f g a) where
  compare = compare1

instance (Show1 f, Show1 g, Show a) => Show (Compose f g a) where
  showsPrec = showsPrec1

instance (Functor f, Functor g) => Functor (Compose f g) where
  fmap f (Compose x) = Compose (fmap (fmap f) x)

instance (Foldable f, Foldable g) => Foldable (Compose f g) where
  foldMap f (Compose t) = foldMap (foldMap f) t

instance (Traversable f, Traversable g) => Traversable (Compose f g) where
  traverse f (Compose t) = Compose <$> traverse (traverse f) t

instance (Applicative f, Applicative g) => Applicative (Compose f g) where
  pure x = Compose (pure (pure x))
  Compose f <*> Compose x = Compose (liftA2 (<*>) f x)

instance (Alternative f, Applicative g) => Alternative (Compose f g) where
  empty = Compose empty
  Compose x <|> Compose y = Compose (x <|> y)
