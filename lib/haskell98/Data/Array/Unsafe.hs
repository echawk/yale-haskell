-- Data.Array.Unsafe (array): the unchecked conversions (Data.Array.Base).
-- castSTUArray reinterprets an unboxed array's elements as another type's
-- (GHC's floatToBytes: a Float array read as Word8s).  Yale Haskell's
-- STUArray holds its elements, not their bytes: the cast is a new array,
-- the elements' little-endian bytes read as the other type's, its bounds
-- the array's (as GHC's), so a write after the cast is not seen through
-- the other.
module Data.Array.Unsafe (unsafeFreeze, unsafeThaw, castSTUArray, CastElem) where

import Data.Array.Base (unsafeFreeze, unsafeThaw, STUArray, MArray(..), getElems, writeArray)
import Control.Monad.ST (ST)
import Data.Bits (shiftL, shiftR, (.|.))
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Word (Word, Word8, Word16, Word32, Word64)
import Data.Ix (Ix, range)
import GHC.Float (castFloatToWord32, castWord32ToFloat, castDoubleToWord64, castWord64ToDouble)

-- An unboxed element's bytes, little-endian.
class CastElem e where
  elemBytes :: e -> [Word8]
  bytesElem :: [Word8] -> e
  elemSize :: e -> Int

le :: Integral a => Int -> a -> [Word8]
le n x = [fromIntegral (toInteger x `shiftR` (8 * i)) | i <- [0 .. n - 1]]

unle :: Num a => [Word8] -> a
unle bs = fromInteger (foldr (\b acc -> acc `shiftL` 8 .|. toInteger b) 0 bs)

instance CastElem Word8 where { elemBytes = le 1; bytesElem = unle; elemSize _ = 1 }
instance CastElem Word16 where { elemBytes = le 2; bytesElem = unle; elemSize _ = 2 }
instance CastElem Word32 where { elemBytes = le 4; bytesElem = unle; elemSize _ = 4 }
instance CastElem Word64 where { elemBytes = le 8; bytesElem = unle; elemSize _ = 8 }
instance CastElem Word where { elemBytes = le 8; bytesElem = unle; elemSize _ = 8 }
instance CastElem Int8 where { elemBytes = le 1; bytesElem = fromIntegral . (unle :: [Word8] -> Word8); elemSize _ = 1 }
instance CastElem Int16 where { elemBytes = le 2; bytesElem = fromIntegral . (unle :: [Word8] -> Word16); elemSize _ = 2 }
instance CastElem Int32 where { elemBytes = le 4; bytesElem = fromIntegral . (unle :: [Word8] -> Word32); elemSize _ = 4 }
instance CastElem Int64 where { elemBytes = le 8; bytesElem = fromIntegral . (unle :: [Word8] -> Word64); elemSize _ = 8 }
instance CastElem Int where { elemBytes = le 8; bytesElem = fromIntegral . (unle :: [Word8] -> Word64); elemSize _ = 8 }
instance CastElem Float where
  elemBytes = elemBytes . castFloatToWord32
  bytesElem = castWord32ToFloat . bytesElem
  elemSize _ = 4
instance CastElem Double where
  elemBytes = elemBytes . castDoubleToWord64
  bytesElem = castWord64ToDouble . bytesElem
  elemSize _ = 8

castSTUArray :: (Ix i, CastElem a, CastElem b, MArray (STUArray s) a (ST s), MArray (STUArray s) b (ST s))
             => STUArray s i a -> ST s (STUArray s i b)
castSTUArray arr = do
  b <- getBounds arr
  xs <- getElems arr
  new <- newArray_ b
  let bytes = concatMap elemBytes xs ++ repeat 0
      out = new `asTypeOf2` (head (chunks bytes))
      size = elemSize out
      chunks bs = let (h, t) = splitAt size bs in bytesElem h : chunks t
  mapM_ (\(i, e) -> writeArray new i e) (zip (range b) (chunks bytes))
  return new
  where asTypeOf2 :: STUArray s i b -> b -> b
        asTypeOf2 _ e = e
