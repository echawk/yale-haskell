-- Data.Functor (base)
module Data.Functor (
    Functor(fmap), (<$), ($>), (<$>), (<&>), void
  ) where

import PreludeModern ((<$>), (<$))
import ControlMonadBase (void)

infixl 4 $>
infixl 1 <&>

($>) :: Functor f => f a -> b -> f b
($>) fa b = fmap (const b) fa

(<&>) :: Functor f => f a -> (a -> b) -> f b
fa <&> f = fmap f fa
