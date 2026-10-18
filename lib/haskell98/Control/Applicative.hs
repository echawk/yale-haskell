-- Control.Applicative (base), for Yale Haskell's Haskell 98 dialect: the
-- classes are PreludeModern's (doc/plans/MICROCABAL.md step 2).
module Control.Applicative (
    Applicative(pure, (<*>), (*>), (<*), liftA2), Alternative(empty, (<|>), some, many),
    (<$>), (<$), (<**>), liftA, liftA3, optional, asum,
    WrappedMonad(WrapMonad, unwrapMonad), Const(Const, getConst),
    ZipList(ZipList, getZipList), WrappedArrow(WrapArrow, unwrapArrow)
  ) where

import Prelude hiding (foldr, length)
import PreludeModern
import Data.Functor.Const (Const(Const, getConst))
import Data.Foldable (asum)
import Control.Arrow (Arrow(arr, (&&&)), ArrowZero(zeroArrow), ArrowPlus((<+>)), (>>>))

-- lists zipped elementwise: pure repeats
newtype ZipList a = ZipList { getZipList :: [a] }
  deriving (Eq, Ord, Show, Read)

instance Functor ZipList where
  fmap f (ZipList xs) = ZipList (map f xs)

instance Applicative ZipList where
  pure x = ZipList (repeat x)
  liftA2 f (ZipList xs) (ZipList ys) = ZipList (zipWith f xs ys)
  ZipList fs <*> ZipList xs = ZipList (zipWith id fs xs)

instance Alternative ZipList where
  empty = ZipList []
  ZipList xs <|> ZipList ys = ZipList (xs ++ drop (length xs) ys)

instance Foldable ZipList where
  foldMap f (ZipList xs) = foldMap f xs
  foldr f z (ZipList xs) = foldr f z xs

instance Traversable ZipList where
  traverse f (ZipList xs) = fmap ZipList (traverse f xs)

-- an arrow as an applicative
newtype WrappedArrow a b c = WrapArrow { unwrapArrow :: a b c }

instance Arrow a => Functor (WrappedArrow a b) where
  fmap f (WrapArrow a) = WrapArrow (a >>> arr f)

instance Arrow a => Applicative (WrappedArrow a b) where
  pure x = WrapArrow (arr (const x))
  liftA2 f (WrapArrow u) (WrapArrow v) = WrapArrow (u &&& v >>> arr (uncurry f))

instance (ArrowZero a, ArrowPlus a) => Alternative (WrappedArrow a b) where
  empty = WrapArrow zeroArrow
  WrapArrow u <|> WrapArrow v = WrapArrow (u <+> v)
