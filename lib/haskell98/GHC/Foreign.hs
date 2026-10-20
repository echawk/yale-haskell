-- GHC.Foreign (base): C strings in a given TextEncoding.  UTF-8
-- (with or without a BOM) and the one-byte encodings (Latin-1, char8,
-- ASCII) are done; another name is taken as UTF-8.
module GHC.Foreign (
    peekCString, peekCStringLen, newCString, newCStringLen,
    withCString, withCStringLen, charIsRepresentable
  ) where

import System.IO (TextEncoding)
import Foreign.C.String (CString, CStringLen)
import Foreign.Ptr (castPtr, plusPtr)
import Foreign.Storable (peek, pokeByteOff)
import Foreign.Marshal.Alloc (mallocBytes, allocaBytes)
import Foreign.Marshal.Array (peekArray)
import Data.Word (Word8)
import Data.Char (ord, chr, toUpper)
import Data.Bits ((.&.), (.|.), shiftL, shiftR)

oneByte :: TextEncoding -> Bool
oneByte te = map toUpper (show te) `elem`
  ["ISO-8859-1", "ISO8859-1", "LATIN1", "CHAR8", "ASCII", "US-ASCII"]

encode :: TextEncoding -> String -> [Word8]
encode te s
  | oneByte te = map (fromIntegral . (.&. 0xFF) . ord) s
  | otherwise = concatMap (utf8 . ord) s
  where
    utf8 c
      | c < 0x80 = [fromIntegral c]
      | c < 0x800 = map fromIntegral [0xC0 .|. shiftR c 6, 0x80 .|. (c .&. 0x3F)]
      | c < 0x10000 = map fromIntegral [0xE0 .|. shiftR c 12, 0x80 .|. (shiftR c 6 .&. 0x3F),
                                        0x80 .|. (c .&. 0x3F)]
      | otherwise = map fromIntegral [0xF0 .|. shiftR c 18, 0x80 .|. (shiftR c 12 .&. 0x3F),
                                      0x80 .|. (shiftR c 6 .&. 0x3F), 0x80 .|. (c .&. 0x3F)]

decode :: TextEncoding -> [Word8] -> String
decode te ws
  | oneByte te = map (chr . fromIntegral) ws
  | otherwise = go (map fromIntegral ws)
  where
    go [] = []
    go (b : bs)
      | b < 0x80 = chr b : go bs
      | b < 0xE0, (c : r) <- bs = chr ((shiftL (b .&. 0x1F) 6) .|. (c .&. 0x3F)) : go r
      | b < 0xF0, (c : d : r) <- bs =
          chr ((shiftL (b .&. 0x0F) 12) .|. (shiftL (c .&. 0x3F) 6) .|. (d .&. 0x3F)) : go r
      | (c : d : e : r) <- bs =
          chr ((shiftL (b .&. 0x07) 18) .|. (shiftL (c .&. 0x3F) 12)
               .|. (shiftL (d .&. 0x3F) 6) .|. (e .&. 0x3F)) : go r
      | otherwise = "\xFFFD"

peekCString :: TextEncoding -> CString -> IO String
peekCString te p = fmap (decode te) (bytesTo0 (castPtr p))
  where bytesTo0 q = do w <- peek q
                        if w == (0 :: Word8) then return []
                          else fmap (w :) (bytesTo0 (q `plusPtr` 1))

peekCStringLen :: TextEncoding -> CStringLen -> IO String
peekCStringLen te (p, n) = fmap (decode te) (peekArray n (castPtr p))

-- | NUL-terminated, in new memory (free it with free).
newCString :: TextEncoding -> String -> IO CString
newCString te s = do
  let ws = encode te s
  p <- mallocBytes (length ws + 1)
  pokeAll p (ws ++ [0])
  return p

newCStringLen :: TextEncoding -> String -> IO CStringLen
newCStringLen te s = do
  let ws = encode te s
  p <- mallocBytes (max 1 (length ws))
  pokeAll p ws
  return (p, length ws)

withCString :: TextEncoding -> String -> (CString -> IO a) -> IO a
withCString te s k = do
  let ws = encode te s ++ [0]
  allocaBytes (length ws) (\p -> pokeAll p ws >> k p)

withCStringLen :: TextEncoding -> String -> (CStringLen -> IO a) -> IO a
withCStringLen te s k = do
  let ws = encode te s
  allocaBytes (max 1 (length ws)) (\p -> pokeAll p ws >> k (p, length ws))

pokeAll :: CString -> [Word8] -> IO ()
pokeAll p ws = mapM_ (\(i, w) -> pokeByteOff p i w) (zip [0 ..] ws)

charIsRepresentable :: TextEncoding -> Char -> IO Bool
charIsRepresentable te c = return (not (oneByte te) || ord c < 256)
