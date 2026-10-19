-- Data.Hashable.Lifted (hashable): hashing for type constructors.
module Data.Hashable.Lifted (
    Hashable1(liftHashWithSalt), Hashable2(liftHashWithSalt2),
    hashWithSalt1, hashWithSalt2, defaultLiftHashWithSalt
  ) where

import Data.Hashable (Hashable(hashWithSalt))
import Data.Functor.Identity (Identity(Identity))
import Data.Functor.Const (Const(Const))
import Data.List.NonEmpty (NonEmpty((:|)))

class Hashable1 t where
  liftHashWithSalt :: (Int -> a -> Int) -> Int -> t a -> Int

class Hashable2 t where
  liftHashWithSalt2 :: (Int -> a -> Int) -> (Int -> b -> Int) -> Int -> t a b -> Int

hashWithSalt1 :: (Hashable1 f, Hashable a) => Int -> f a -> Int
hashWithSalt1 = liftHashWithSalt hashWithSalt

hashWithSalt2 :: (Hashable2 f, Hashable a, Hashable b) => Int -> f a b -> Int
hashWithSalt2 = liftHashWithSalt2 hashWithSalt hashWithSalt

defaultLiftHashWithSalt :: (Hashable2 f, Hashable a) => (Int -> b -> Int) -> Int -> f a b -> Int
defaultLiftHashWithSalt h = liftHashWithSalt2 hashWithSalt h

instance Hashable1 Maybe where
  liftHashWithSalt _ s Nothing = hashWithSalt s (0 :: Int)
  liftHashWithSalt h s (Just a) = h (hashWithSalt s (1 :: Int)) a

instance Hashable1 [] where
  liftHashWithSalt h s xs = hashWithSalt (foldl h s xs) (length xs)

instance Hashable1 NonEmpty where
  liftHashWithSalt h s (x :| xs) = liftHashWithSalt h (h s x) xs

instance Hashable a => Hashable1 (Either a) where
  liftHashWithSalt = defaultLiftHashWithSalt

instance Hashable2 Either where
  liftHashWithSalt2 h _ s (Left a) = h (hashWithSalt s (0 :: Int)) a
  liftHashWithSalt2 _ h s (Right b) = h (hashWithSalt s (1 :: Int)) b

instance Hashable a => Hashable1 ((,) a) where
  liftHashWithSalt = defaultLiftHashWithSalt

instance Hashable2 (,) where
  liftHashWithSalt2 h1 h2 s (a, b) = h2 (h1 s a) b

instance Hashable1 Identity where
  liftHashWithSalt h s (Identity a) = h s a

instance Hashable a => Hashable1 (Const a) where
  liftHashWithSalt = defaultLiftHashWithSalt

instance Hashable2 Const where
  liftHashWithSalt2 h _ s (Const a) = h s a
