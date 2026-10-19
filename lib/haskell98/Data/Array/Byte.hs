{-# LANGUAGE MagicHash, UnboxedTuples #-}
-- Data.Array.Byte (base 4.17): boxed byte arrays over GHC.Exts' ByteArray#
-- (GHC.PrimOps).
module Data.Array.Byte (ByteArray(..), MutableByteArray(..)) where

import PreludeModern (Semigroup((<>)), Monoid(mempty, mconcat))
import GHC.Exts
import Data.Word (Word8)
import Numeric (showHex)

data ByteArray = ByteArray ByteArray#

data MutableByteArray s = MutableByteArray (MutableByteArray# s)

sizeOf :: ByteArray -> Int
sizeOf (ByteArray b) = sizeofByteArray# b

bytes :: ByteArray -> [Word8]
bytes (ByteArray b) = [ fromIntegral (indexWord8Array# b i) | i <- [0 .. sizeofByteArray# b - 1] ]

fromBytes :: [Word8] -> ByteArray
fromBytes ws = runRW# (\s -> case newByteArray# n s of
  (# s1, mb #) -> case fill mb 0 ws s1 of
    s2 -> case unsafeFreezeByteArray# mb s2 of (# _, b #) -> ByteArray b)
  where n = length ws
        fill _ _ [] s = s
        fill mb i (w : rest) s = fill mb (i + 1) rest (writeWord8Array# mb i (fromIntegral w) s)

instance Eq ByteArray where
  a@(ByteArray x) == b@(ByteArray y) =
    sizeOf a == sizeOf b && compareByteArrays# x 0 y 0 (sizeOf a) == 0

instance Ord ByteArray where
  compare a@(ByteArray x) b@(ByteArray y) =
    case compareByteArrays# x 0 y 0 (min (sizeOf a) (sizeOf b)) of
      0 -> compare (sizeOf a) (sizeOf b)
      n -> compare n 0

instance Show ByteArray where
  showsPrec _ a = showChar '[' . go (bytes a) . showChar ']'
    where go [] = id
          go [w] = byte w
          go (w : ws) = byte w . showString ", " . go ws
          byte w = showString "0x" . (if w < 16 then showChar '0' else id) . showHex w

instance Semigroup ByteArray where
  a <> b = fromBytes (bytes a ++ bytes b)

instance Monoid ByteArray where
  mempty = fromBytes []
  mconcat as = fromBytes (concatMap bytes as)

instance Eq (MutableByteArray s) where
  MutableByteArray a == MutableByteArray b = sameMutableByteArray# a b == 1
