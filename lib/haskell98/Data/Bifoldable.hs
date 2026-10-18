-- Data.Bifoldable (base): folds over the two parameters of a type.
module Data.Bifoldable (
    Bifoldable(bifold, bifoldMap, bifoldr, bifoldl),
    bifoldr', bifoldl', bitraverse_, bifor_, bimapM_, bisequence_,
    bisequenceA_, biasum, biList, binull, bilength, bielem, bisum,
    biproduct, biconcat, biconcatMap, biand, bior, biany, biall,
    bimaximum, biminimum, bifind
  ) where

import Prelude hiding (foldr, maximum, minimum)
import PreludeModern
import Data.Functor.Const (Const(Const))
import Data.Semigroup (Arg(Arg))
import Data.Maybe (listToMaybe)
import Control.Applicative (Alternative(empty, (<|>)))

-- As base: an instance defines bifoldMap or bifoldr.
class Bifoldable p where
  bifold    :: Monoid m => p m m -> m
  bifoldMap :: Monoid m => (a -> m) -> (b -> m) -> p a b -> m
  bifoldr   :: (a -> c -> c) -> (b -> c -> c) -> c -> p a b -> c
  bifoldl   :: (c -> a -> c) -> (c -> b -> c) -> c -> p a b -> c

  bifold = bifoldMap id id
  bifoldMap f g = bifoldr (\a m -> f a <> m) (\b m -> g b <> m) mempty
  bifoldr f g z t = biListr (bifoldMap (\a -> [Left a]) (\b -> [Right b]) t)
    where biListr = foldr (\e c -> either (`f` c) (`g` c) e) z
  bifoldl f g z t = bifoldr (\a k c -> k (f c a)) (\b k c -> k (g c b)) id t z

instance Bifoldable (,) where
  bifoldMap f g (a, b) = f a <> g b

instance Bifoldable ((,,) x) where
  bifoldMap f g (_, a, b) = f a <> g b

instance Bifoldable ((,,,) x y) where
  bifoldMap f g (_, _, a, b) = f a <> g b

instance Bifoldable ((,,,,) x y z) where
  bifoldMap f g (_, _, _, a, b) = f a <> g b

instance Bifoldable ((,,,,,) x y z w) where
  bifoldMap f g (_, _, _, _, a, b) = f a <> g b

instance Bifoldable ((,,,,,,) x y z w v) where
  bifoldMap f g (_, _, _, _, _, a, b) = f a <> g b

instance Bifoldable Arg where
  bifoldMap f g (Arg a b) = f a <> g b

instance Bifoldable Const where
  bifoldMap f _ (Const a) = f a

instance Bifoldable Either where
  bifoldMap f _ (Left a) = f a
  bifoldMap _ g (Right b) = g b

bifoldr' :: Bifoldable t => (a -> c -> c) -> (b -> c -> c) -> c -> t a b -> c
bifoldr' f g z t = bifoldl (\k a c -> k $! f a c) (\k b c -> k $! g b c) id t z

bifoldl' :: Bifoldable t => (c -> a -> c) -> (c -> b -> c) -> c -> t a b -> c
bifoldl' f g z t = bifoldr (\a k c -> k $! f c a) (\b k c -> k $! g c b) id t z

bitraverse_ :: (Bifoldable t, Applicative f) => (a -> f c) -> (b -> f d) -> t a b -> f ()
bitraverse_ f g = bifoldr ((*>) . f) ((*>) . g) (pure ())

bifor_ :: (Bifoldable t, Applicative f) => t a b -> (a -> f c) -> (b -> f d) -> f ()
bifor_ t f g = bitraverse_ f g t

bimapM_ :: (Bifoldable t, Applicative f) => (a -> f c) -> (b -> f d) -> t a b -> f ()
bimapM_ = bitraverse_

bisequenceA_ :: (Bifoldable t, Applicative f) => t (f a) (f b) -> f ()
bisequenceA_ = bitraverse_ id id

bisequence_ :: (Bifoldable t, Applicative f) => t (f a) (f b) -> f ()
bisequence_ = bisequenceA_

biasum :: (Bifoldable t, Alternative f) => t (f a) (f a) -> f a
biasum = bifoldr (<|>) (<|>) empty

biList :: Bifoldable t => t a a -> [a]
biList = bifoldr (:) (:) []

binull :: Bifoldable t => t a b -> Bool
binull = bifoldr (\_ _ -> False) (\_ _ -> False) True

bilength :: Bifoldable t => t a b -> Int
bilength = bifoldl' (\c _ -> c + 1) (\c _ -> c + 1) 0

bielem :: (Bifoldable t, Eq a) => a -> t a a -> Bool
bielem x = biany (== x) (== x)

biconcat :: Bifoldable t => t [a] [a] -> [a]
biconcat = bifoldr (++) (++) []

biconcatMap :: Bifoldable t => (a -> [c]) -> (b -> [c]) -> t a b -> [c]
biconcatMap f g = bifoldr ((++) . f) ((++) . g) []

bisum :: (Bifoldable t, Num a) => t a a -> a
bisum = bifoldl' (+) (+) 0

biproduct :: (Bifoldable t, Num a) => t a a -> a
biproduct = bifoldl' (*) (*) 1

biand :: Bifoldable t => t Bool Bool -> Bool
biand = biall id id

bior :: Bifoldable t => t Bool Bool -> Bool
bior = biany id id

biany :: Bifoldable t => (a -> Bool) -> (b -> Bool) -> t a b -> Bool
biany p q = bifoldr (\a r -> p a || r) (\b r -> q b || r) False

biall :: Bifoldable t => (a -> Bool) -> (b -> Bool) -> t a b -> Bool
biall p q = bifoldr (\a r -> p a && r) (\b r -> q b && r) True

bimaximum :: (Bifoldable t, Ord a) => t a a -> a
bimaximum = maximum . biList

biminimum :: (Bifoldable t, Ord a) => t a a -> a
biminimum = minimum . biList

bifind :: Bifoldable t => (a -> Bool) -> t a a -> Maybe a
bifind p = listToMaybe . filter p . biList
