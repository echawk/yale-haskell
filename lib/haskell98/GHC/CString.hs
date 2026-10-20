{-# LANGUAGE MagicHash #-}
-- GHC.CString (ghc-prim): C strings at an Addr# (a Ptr here, GHC.Exts).
module GHC.CString (
    unpackCString#, unpackAppendCString#, unpackFoldrCString#,
    unpackCStringUtf8#, unpackAppendCStringUtf8#, unpackFoldrCStringUtf8#,
    unpackNBytes#, cstringLength#
  ) where

import GHC.Exts (Addr#)
import Foreign.Ptr (Ptr, plusPtr)
import Foreign.Storable (peek)
import Data.Word (Word8)
import Data.Char (chr)
import Data.Bits ((.&.), (.|.), shiftL)
import Unsafe.Coerce (unsafeCoerce)
import System.IO.Unsafe (unsafePerformIO)

ptr :: Addr# -> Ptr Word8
ptr a = unsafeCoerce a

-- | The bytes up to the NUL.
bytes :: Addr# -> [Word8]
bytes a = unsafePerformIO (go (ptr a))
  where go p = do w <- peek p
                  if w == 0 then return [] else fmap (w :) (go (p `plusPtr` 1))

cstringLength# :: Addr# -> Int
cstringLength# = length . bytes

unpackCString# :: Addr# -> [Char]
unpackCString# a = map (chr . fromIntegral) (bytes a)

unpackAppendCString# :: Addr# -> [Char] -> [Char]
unpackAppendCString# a rest = unpackCString# a ++ rest

unpackFoldrCString# :: Addr# -> (Char -> b -> b) -> b -> b
unpackFoldrCString# a f z = foldr f z (unpackCString# a)

unpackCStringUtf8# :: Addr# -> [Char]
unpackCStringUtf8# a = decode (map fromIntegral (bytes a))

unpackAppendCStringUtf8# :: Addr# -> [Char] -> [Char]
unpackAppendCStringUtf8# a rest = unpackCStringUtf8# a ++ rest

unpackFoldrCStringUtf8# :: Addr# -> (Char -> b -> b) -> b -> b
unpackFoldrCStringUtf8# a f z = foldr f z (unpackCStringUtf8# a)

-- | The first N bytes, as Latin-1 Chars.
unpackNBytes# :: Addr# -> Int -> [Char]
unpackNBytes# a n = unsafePerformIO (mapM (\i -> fmap (chr . fromIntegral) (peek (ptr a `plusPtr` i) :: IO Word8)) [0 .. n - 1])

decode :: [Int] -> [Char]
decode [] = []
decode (b : bs)
  | b < 0x80 = chr b : decode bs
  | b < 0xE0, (c : r) <- bs = chr (((b .&. 0x1F) `shiftL` 6) .|. (c .&. 0x3F)) : decode r
  | b < 0xF0, (c : d : r) <- bs =
      chr (((b .&. 0x0F) `shiftL` 12) .|. ((c .&. 0x3F) `shiftL` 6) .|. (d .&. 0x3F)) : decode r
  | (c : d : e : r) <- bs =
      chr (((b .&. 0x07) `shiftL` 18) .|. ((c .&. 0x3F) `shiftL` 12) .|. ((d .&. 0x3F) `shiftL` 6) .|. (e .&. 0x3F)) : decode r
  | otherwise = ['\xFFFD']
