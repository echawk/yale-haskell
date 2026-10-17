-- Control.Applicative.Lift (transformers): adding pure values to an
-- applicative functor, and Errors, the applicative that collects them.
module Control.Applicative.Lift (
    Lift(Pure, Other), unLift, mapLift, elimLift,
    Errors, runErrors, failure, eitherToErrors
  ) where

import Prelude hiding (foldr)
import PreludeModern
import Data.Functor.Constant (Constant(Constant, getConstant))

data Lift f a = Pure a | Other (f a)

instance (Eq a, Eq (f a)) => Eq (Lift f a) where
  Pure x == Pure y = x == y
  Other x == Other y = x == y
  _ == _ = False

instance (Show a, Show (f a)) => Show (Lift f a) where
  showsPrec d (Pure x) = showParen (d > 10) (showString "Pure " . showsPrec 11 x)
  showsPrec d (Other x) = showParen (d > 10) (showString "Other " . showsPrec 11 x)

instance Functor f => Functor (Lift f) where
  fmap f (Pure x) = Pure (f x)
  fmap f (Other y) = Other (fmap f y)

instance Foldable f => Foldable (Lift f) where
  foldMap f (Pure x) = f x
  foldMap f (Other y) = foldMap f y
  foldr f z (Pure x) = f x z
  foldr f z (Other y) = foldr f z y

instance Traversable f => Traversable (Lift f) where
  traverse f (Pure x) = Pure <$> f x
  traverse f (Other y) = Other <$> traverse f y

instance Applicative f => Applicative (Lift f) where
  pure = Pure
  Pure f <*> ax = fmap f ax
  Other f <*> Pure x = Other (fmap ($ x) f)
  Other f <*> Other y = Other (f <*> y)

instance Alternative f => Alternative (Lift f) where
  empty = Other empty
  Pure x <|> _ = Pure x
  Other _ <|> Pure y = Pure y
  Other x <|> Other y = Other (x <|> y)

unLift :: Applicative f => Lift f a -> f a
unLift (Pure x) = pure x
unLift (Other e) = e

mapLift :: (f a -> g a) -> Lift f a -> Lift g a
mapLift _ (Pure x) = Pure x
mapLift f (Other e) = Other (f e)

elimLift :: (a -> r) -> (f a -> r) -> Lift f a -> r
elimLift f _ (Pure x) = f x
elimLift _ g (Other e) = g e

type Errors e = Lift (Constant e)

runErrors :: Errors e a -> Either e a
runErrors (Other (Constant e)) = Left e
runErrors (Pure x) = Right x

failure :: e -> Errors e a
failure e = Other (Constant e)

eitherToErrors :: Either e a -> Errors e a
eitherToErrors = either failure Pure
