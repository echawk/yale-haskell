-- Control.DeepSeq (deepseq).  rnf evaluates fully for the base types;
-- an instance without rnf (deriving NFData, or anyclass) evaluates to
-- weak head normal form only, where deepseq's Generic default would go
-- all the way (only when evaluation happens differs).
module Control.DeepSeq (
    NFData(rnf), deepseq, force, ($!!), (<$!!>), rwhnf, rnf1, rnf2,
    NFData1(liftRnf), NFData2(liftRnf2), rnfList
  ) where

import PreludeModern (Semigroup, Monoid, NonEmpty((:|)))
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Word (Word, Word8, Word16, Word32, Word64)
import Data.Ratio (Ratio)
import Data.Complex (Complex((:+)))
import Data.Functor.Identity (Identity(Identity))
import Data.Functor.Const (Const(Const))
import Data.Proxy (Proxy(Proxy))

infixr 0 $!!, `deepseq`
infixl 4 <$!!>

class NFData a where
  rnf :: a -> ()
  rnf x = x `seq` ()

rwhnf :: a -> ()
rwhnf x = x `seq` ()

-- deepseq's lifted classes, for type constructors
class NFData1 f where
  liftRnf :: (a -> ()) -> f a -> ()

class NFData2 p where
  liftRnf2 :: (a -> ()) -> (b -> ()) -> p a b -> ()

rnf1 :: (NFData1 f, NFData a) => f a -> ()
rnf1 = liftRnf rnf

rnf2 :: (NFData2 p, NFData a, NFData b) => p a b -> ()
rnf2 = liftRnf2 rnf rnf

rnfList :: NFData a => [a] -> ()
rnfList = rnf

instance NFData1 [] where
  liftRnf _ [] = ()
  liftRnf r (x : xs) = r x `seq` liftRnf r xs

instance NFData1 Maybe where
  liftRnf _ Nothing = ()
  liftRnf r (Just x) = r x

instance NFData a => NFData1 (Either a) where
  liftRnf = liftRnf2 rnf

instance NFData a => NFData1 ((,) a) where
  liftRnf = liftRnf2 rnf

instance NFData2 Either where
  liftRnf2 l _ (Left a) = l a
  liftRnf2 _ r (Right b) = r b

instance NFData2 (,) where
  liftRnf2 l r (a, b) = l a `seq` r b

deepseq :: NFData a => a -> b -> b
deepseq a b = rnf a `seq` b

force :: NFData a => a -> a
force x = x `deepseq` x

($!!) :: NFData a => (a -> b) -> a -> b
f $!! x = x `deepseq` f x

(<$!!>) :: (Monad m, NFData b) => (a -> b) -> m a -> m b
f <$!!> m = m >>= \x -> return $!! f x

instance NFData Int
instance NFData Integer
instance NFData Float
instance NFData Double
instance NFData Char
instance NFData Bool
instance NFData Ordering
instance NFData ()

instance NFData a => NFData [a] where
  rnf [] = ()
  rnf (x : xs) = rnf x `seq` rnf xs

instance NFData a => NFData (Maybe a) where
  rnf Nothing = ()
  rnf (Just x) = rnf x

instance (NFData a, NFData b) => NFData (Either a b) where
  rnf (Left a) = rnf a
  rnf (Right b) = rnf b

instance (NFData a, NFData b) => NFData (a, b) where
  rnf (a, b) = rnf a `seq` rnf b

instance (NFData a, NFData b, NFData c) => NFData (a, b, c) where
  rnf (a, b, c) = rnf a `seq` rnf b `seq` rnf c

instance (NFData a, NFData b, NFData c, NFData d) => NFData (a, b, c, d) where
  rnf (a, b, c, d) = rnf a `seq` rnf b `seq` rnf c `seq` rnf d

instance NFData (a -> b)

instance NFData Int8
instance NFData Int16
instance NFData Int32
instance NFData Int64
instance NFData Word
instance NFData Word8
instance NFData Word16
instance NFData Word32
instance NFData Word64

-- a Ratio's fields are strict: weak head normal form is normal form
instance NFData a => NFData (Ratio a) where
  rnf x = x `seq` ()

instance NFData a => NFData (Complex a) where
  rnf (x :+ y) = rnf x `seq` rnf y

instance NFData a => NFData (NonEmpty a) where
  rnf (x :| xs) = rnf x `seq` rnf xs

instance NFData1 NonEmpty where
  liftRnf r (x :| xs) = r x `seq` liftRnf r xs

instance NFData a => NFData (Identity a) where
  rnf (Identity a) = rnf a

instance NFData1 Identity where
  liftRnf r (Identity a) = r a

instance NFData a => NFData (Const a b) where
  rnf (Const a) = rnf a

instance NFData (Proxy a) where
  rnf Proxy = ()

instance NFData1 Proxy where
  liftRnf _ Proxy = ()
