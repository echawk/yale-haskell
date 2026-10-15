-- Data.Hashable (hashable), for Yale Haskell: the class and instances for
-- the common types.  Hashes are FNV-1 style combinations over the 63-bit
-- Int; they are not hashable's values (which differ between platforms
-- and versions anyway), only consistent with Eq.
module Data.Hashable (Hashable(hashWithSalt, hash), defaultSalt, hashUsing) where

import Data.Bits (xor)
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Word (Word, Word8, Word16, Word32, Word64)
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.ByteString as B
import qualified Data.Map as Map
import qualified Data.Set as Set
import Numeric.Natural (Natural)

infixl 0 `hashWithSalt`

defaultSalt :: Int
defaultSalt = -2578643520546668380   -- hashable's, on 64-bit platforms

class Hashable a where
  hashWithSalt :: Int -> a -> Int
  hash :: a -> Int
  hash = hashWithSalt defaultSalt

-- FNV-1's step, in Integer and reduced modulo a prime below 2^61 (Int is
-- the fixnum here, and its products are not wrapped)
combine :: Int -> Int -> Int
combine h x = fromInteger (((toInteger h * 16777619) `xor` toInteger x) `mod` 2305843009213693951)

hashUsing :: Hashable b => (a -> b) -> Int -> a -> Int
hashUsing f salt x = hashWithSalt salt (f x)

instance Hashable Int where
  hashWithSalt = combine
  hash n = n
instance Hashable Integer where
  hashWithSalt s n = combine s (fromInteger (n `mod` 4611686018427387847))
instance Hashable Natural where
  hashWithSalt s n = hashWithSalt s (toInteger n)
instance Hashable Char where
  hashWithSalt s c = combine s (fromEnum c)
instance Hashable Bool where
  hashWithSalt s b = combine s (fromEnum b)
instance Hashable Ordering where
  hashWithSalt s o = combine s (fromEnum o)
instance Hashable () where
  hashWithSalt s () = combine s 0
instance Hashable Double where
  hashWithSalt s d = hashWithSalt s (decodeFloat d)
instance Hashable Float where
  hashWithSalt s d = hashWithSalt s (decodeFloat d)
instance Hashable Int8 where hashWithSalt = hashUsing toInteger
instance Hashable Int16 where hashWithSalt = hashUsing toInteger
instance Hashable Int32 where hashWithSalt = hashUsing toInteger
instance Hashable Int64 where hashWithSalt = hashUsing toInteger
instance Hashable Word where hashWithSalt = hashUsing toInteger
instance Hashable Word8 where hashWithSalt = hashUsing toInteger
instance Hashable Word16 where hashWithSalt = hashUsing toInteger
instance Hashable Word32 where hashWithSalt = hashUsing toInteger
instance Hashable Word64 where hashWithSalt = hashUsing toInteger
instance Hashable a => Hashable [a] where
  hashWithSalt s xs = foldl hashWithSalt (combine s (length xs)) xs
instance Hashable a => Hashable (NonEmpty a) where
  hashWithSalt s (x :| xs) = hashWithSalt s (x : xs)
instance Hashable a => Hashable (Maybe a) where
  hashWithSalt s Nothing = combine s 0
  hashWithSalt s (Just x) = hashWithSalt (combine s 1) x
instance (Hashable a, Hashable b) => Hashable (Either a b) where
  hashWithSalt s (Left x) = hashWithSalt (combine s 0) x
  hashWithSalt s (Right y) = hashWithSalt (combine s 1) y
instance (Hashable a, Hashable b) => Hashable (a, b) where
  hashWithSalt s (a, b) = s `hashWithSalt` a `hashWithSalt` b
instance (Hashable a, Hashable b, Hashable c) => Hashable (a, b, c) where
  hashWithSalt s (a, b, c) = s `hashWithSalt` a `hashWithSalt` b `hashWithSalt` c
instance (Hashable a, Hashable b, Hashable c, Hashable d) => Hashable (a, b, c, d) where
  hashWithSalt s (a, b, c, d) = s `hashWithSalt` a `hashWithSalt` b `hashWithSalt` c `hashWithSalt` d
instance Hashable T.Text where
  hashWithSalt s t = T.foldl' (\h c -> combine h (fromEnum c)) (combine s (T.length t)) t
instance Hashable TL.Text where
  hashWithSalt s t = hashWithSalt s (TL.toStrict t)
instance Hashable B.ByteString where
  hashWithSalt s b = B.foldl' (\h w -> combine h (fromIntegral w)) (combine s (B.length b)) b
instance (Hashable k, Hashable v) => Hashable (Map.Map k v) where
  hashWithSalt s m = hashWithSalt s (Map.toList m)
instance Hashable a => Hashable (Set.Set a) where
  hashWithSalt s m = hashWithSalt s (Set.toList m)
