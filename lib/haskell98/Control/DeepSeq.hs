-- Control.DeepSeq (deepseq).  rnf evaluates fully for the base types;
-- an instance without rnf (deriving NFData, or anyclass) evaluates to
-- weak head normal form only, where deepseq's Generic default would go
-- all the way (only when evaluation happens differs).
module Control.DeepSeq (
    NFData(rnf), deepseq, force, ($!!), (<$!!>), rwhnf, rnf1
  ) where

import PreludeModern (Semigroup, Monoid)

infixr 0 $!!, `deepseq`
infixl 4 <$!!>

class NFData a where
  rnf :: a -> ()
  rnf x = x `seq` ()

rwhnf :: a -> ()
rwhnf x = x `seq` ()

rnf1 :: NFData a => [a] -> ()
rnf1 = rnf

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
