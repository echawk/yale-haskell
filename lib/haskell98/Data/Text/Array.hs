{-# LANGUAGE MagicHash, UnboxedTuples, RankNTypes #-}
-- Data.Text.Array (text 2): the byte arrays text's internals hold UTF-8
-- in (Data.Text.Internal's Text arr off len).
module Data.Text.Array (
    Array(ByteArray), MArray(MutableByteArray),
    unsafeIndex, new, unsafeWrite, unsafeFreeze, run, empty, length,
    toList, fromList, copyI
  ) where

import Prelude hiding (length)
import qualified Prelude as P
import Data.Word (Word8)
import GHC.Exts hiding (fromList, toList)
import GHC.ST (ST(ST))
import Control.Monad.ST (runST)

data Array = ByteArray ByteArray#

data MArray s = MutableByteArray (MutableByteArray# s)

unsafeIndex :: Array -> Int -> Word8
unsafeIndex (ByteArray b) i = fromIntegral (indexWord8Array# b i)

length :: Array -> Int
length (ByteArray b) = sizeofByteArray# b

new :: Int -> ST s (MArray s)
new n = ST (\s -> case newByteArray# n s of (# s1, mb #) -> (# s1, MutableByteArray mb #))

unsafeWrite :: MArray s -> Int -> Word8 -> ST s ()
unsafeWrite (MutableByteArray mb) i w =
  ST (\s -> case writeWord8Array# mb i (fromIntegral w) s of s1 -> (# s1, () #))

unsafeFreeze :: MArray s -> ST s Array
unsafeFreeze (MutableByteArray mb) =
  ST (\s -> case unsafeFreezeByteArray# mb s of (# s1, b #) -> (# s1, ByteArray b #))

run :: (forall s. ST s (MArray s)) -> Array
run k = runST (k >>= unsafeFreeze)

-- | Copies COUNT bytes of SRC from SOFF to DST at DOFF.
copyI :: Int -> MArray s -> Int -> Array -> Int -> ST s ()
copyI count dst doff src soff =
  mapM_ (\i -> unsafeWrite dst (doff + i) (unsafeIndex src (soff + i))) [0 .. count - 1]

empty :: Array
empty = fromList []

toList :: Array -> Int -> Int -> [Word8]
toList arr off len = [ unsafeIndex arr i | i <- [off .. off + len - 1] ]

fromList :: [Word8] -> Array
fromList ws = run (do
  ma <- new (P.length ws)
  mapM_ (\(i, w) -> unsafeWrite ma i w) (zip [0 ..] ws)
  return ma)
