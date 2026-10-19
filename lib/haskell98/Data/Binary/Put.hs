-- Data.Binary.Put (binary): encoding, a writer of Data.Binary.Builder.
module Data.Binary.Put (
    Put, PutM(..), runPut, runPutM, putBuilder, execPut, flush,
    putWord8, putInt8, putByteString, putLazyByteString,
    putWord16be, putWord32be, putWord64be, putInt16be, putInt32be,
    putInt64be, putFloatbe, putDoublebe, putWord16le, putWord32le,
    putWord64le, putInt16le, putInt32le, putInt64le, putFloatle,
    putDoublele, putWordhost, putWord16host, putWord32host, putWord64host,
    putInthost, putInt16host, putInt32host, putInt64host, putFloathost,
    putDoublehost, putCharUtf8, putStringUtf8,
    floatToWord32, doubleToWord64
  ) where

import PreludeModern (Semigroup((<>)), Monoid(mempty, mappend))
import Control.Applicative (Applicative(pure, (<*>)))
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.Binary.Builder (Builder, toLazyByteString)
import qualified Data.Binary.Builder as B
import Data.Int
import Data.Word

newtype PutM a = PutM (a, Builder)

type Put = PutM ()

unPut :: PutM a -> (a, Builder)
unPut (PutM p) = p

instance Functor PutM where
  fmap f (PutM (a, b)) = PutM (f a, b)

instance Applicative PutM where
  pure a = PutM (a, mempty)
  PutM (f, b) <*> PutM (a, b') = PutM (f a, b <> b')

instance Monad PutM where
  return = pure
  PutM (a, b) >>= k = let PutM (c, b') = k a in PutM (c, b <> b')

instance Semigroup (PutM ()) where
  a <> b = a >> b
instance Monoid (PutM ()) where
  mempty = return ()
  mappend = (<>)

tell :: Builder -> Put
tell b = PutM ((), b)

putBuilder :: Builder -> Put
putBuilder = tell

execPut :: PutM a -> Builder
execPut = snd . unPut

runPut :: Put -> L.ByteString
runPut = toLazyByteString . execPut

runPutM :: PutM a -> (a, L.ByteString)
runPutM (PutM (a, b)) = (a, toLazyByteString b)

flush :: Put
flush = return ()

putWord8 :: Word8 -> Put
putWord8 = tell . B.singleton
putInt8 :: Int8 -> Put
putInt8 = putWord8 . fromIntegral
putByteString :: S.ByteString -> Put
putByteString = tell . B.fromByteString
putLazyByteString :: L.ByteString -> Put
putLazyByteString = tell . B.fromLazyByteString

putWord16be, putWord16le, putWord16host :: Word16 -> Put
putWord16be = tell . B.putWord16be
putWord16le = tell . B.putWord16le
putWord16host = tell . B.putWord16host
putWord32be, putWord32le, putWord32host :: Word32 -> Put
putWord32be = tell . B.putWord32be
putWord32le = tell . B.putWord32le
putWord32host = tell . B.putWord32host
putWord64be, putWord64le, putWord64host :: Word64 -> Put
putWord64be = tell . B.putWord64be
putWord64le = tell . B.putWord64le
putWord64host = tell . B.putWord64host
putWordhost :: Word -> Put
putWordhost = tell . B.putWordhost
putInt16be, putInt16le, putInt16host :: Int16 -> Put
putInt16be = tell . B.putInt16be
putInt16le = tell . B.putInt16le
putInt16host = tell . B.putInt16host
putInt32be, putInt32le, putInt32host :: Int32 -> Put
putInt32be = tell . B.putInt32be
putInt32le = tell . B.putInt32le
putInt32host = tell . B.putInt32host
putInt64be, putInt64le, putInt64host :: Int64 -> Put
putInt64be = tell . B.putInt64be
putInt64le = tell . B.putInt64le
putInt64host = tell . B.putInt64host
putInthost :: Int -> Put
putInthost = tell . B.putInthost

putCharUtf8 :: Char -> Put
putCharUtf8 = tell . B.putCharUtf8
putStringUtf8 :: String -> Put
putStringUtf8 = tell . B.putStringUtf8

-- IEEE 754 bits of a value (rounding as encodeFloat does)
floatToWord32 :: Float -> Word32
floatToWord32 x = fromInteger (toBits 23 8 127 x)

doubleToWord64 :: Double -> Word64
doubleToWord64 x = fromInteger (toBits 52 11 1023 x)

toBits :: RealFloat a => Int -> Int -> Int -> a -> Integer
toBits mbits ebits bias x
  | isNaN x = (2 ^ ebits - 1) * 2 ^ mbits + 2 ^ (mbits - 1)
  | isInfinite x = sign + (2 ^ ebits - 1) * 2 ^ mbits
  | x == 0 = if isNegativeZero x then 2 ^ (mbits + ebits) else 0
  | otherwise =
      let (m, e) = decodeFloat (abs x)
          -- abs x = m * 2^e with m having floatDigits bits
          e' = e + mbits + bias       -- the biased exponent of a normal number
      in if e' >= 1
           then sign + toInteger e' * 2 ^ mbits + (m - 2 ^ mbits)
           else sign + m `div` (2 ^ (1 - e'))   -- subnormal
  where sign = if x < 0 then 2 ^ (mbits + ebits) else 0

putFloatbe, putFloatle, putFloathost :: Float -> Put
putFloatbe = putWord32be . floatToWord32
putFloatle = putWord32le . floatToWord32
putFloathost = putFloatle
putDoublebe, putDoublele, putDoublehost :: Double -> Put
putDoublebe = putWord64be . doubleToWord64
putDoublele = putWord64le . doubleToWord64
putDoublehost = putDoublele
