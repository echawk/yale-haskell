-- Data.ByteString.Builder.Prim (bytestring): primitive encodings, here a
-- value's bytes (a FixedPrim's the same number for every value).
module Data.ByteString.Builder.Prim (
    FixedPrim(..), BoundedPrim(..), Contravariant'(..), Monoidal'(..), (>$<), (>*<),
    emptyF, emptyB, liftFixedToBounded, condB, eitherB,
    primFixed, primBounded, primMapListFixed, primMapListBounded,
    char7, char8, charUtf8, word8, int8, word16BE, word16LE, word32BE,
    word32LE, word64BE, word64LE, word16HexFixed, word32HexFixed,
    word8HexFixed, int16BE, int16LE, int32BE, int32LE, int64BE, int64LE,
    intHost, int16Host, int32Host, int64Host, wordHost, word16Host,
    word32Host, word64Host, primMapByteStringBounded,
    primMapLazyByteStringBounded
  ) where

import Data.ByteString.Builder (Builder)
import qualified Data.ByteString.Builder as B
import Data.Word (Word, Word8, Word16, Word32, Word64)
import Data.Int (Int8, Int16, Int32, Int64)
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.Bits ((.&.), (.|.), shiftR)
import Data.Char (ord, intToDigit)
import PreludeModern (Monoid(mempty, mconcat))

-- A FixedPrim has its size and a BoundedPrim its bound (Prim.Internal).
data FixedPrim a = FixedPrim Int (a -> [Word8])
data BoundedPrim a = BoundedPrim Int (a -> [Word8])

-- bytestring's contravariant and monoidal combinators
class Contravariant' p where
  contramapP :: (a -> b) -> p b -> p a
class Monoidal' p where
  pairP :: p a -> p b -> p (a, b)

instance Contravariant' FixedPrim where
  contramapP f (FixedPrim n e) = FixedPrim n (e . f)
instance Contravariant' BoundedPrim where
  contramapP f (BoundedPrim n e) = BoundedPrim n (e . f)
instance Monoidal' FixedPrim where
  pairP (FixedPrim n1 e1) (FixedPrim n2 e2) = FixedPrim (n1 + n2) (\(a, b) -> e1 a ++ e2 b)
instance Monoidal' BoundedPrim where
  pairP (BoundedPrim n1 e1) (BoundedPrim n2 e2) = BoundedPrim (n1 + n2) (\(a, b) -> e1 a ++ e2 b)

infixl 4 >$<
infixr 5 >*<

(>$<) :: Contravariant' p => (a -> b) -> p b -> p a
(>$<) = contramapP

(>*<) :: Monoidal' p => p a -> p b -> p (a, b)
(>*<) = pairP

emptyF :: FixedPrim a
emptyF = FixedPrim 0 (const [])

emptyB :: BoundedPrim a
emptyB = BoundedPrim 0 (const [])

liftFixedToBounded :: FixedPrim a -> BoundedPrim a
liftFixedToBounded (FixedPrim n e) = BoundedPrim n e

condB :: (a -> Bool) -> BoundedPrim a -> BoundedPrim a -> BoundedPrim a
condB p (BoundedPrim n t) (BoundedPrim m f) = BoundedPrim (max n m) (\a -> if p a then t a else f a)

eitherB :: BoundedPrim a -> BoundedPrim b -> BoundedPrim (Either a b)
eitherB (BoundedPrim n l) (BoundedPrim m r) = BoundedPrim (max n m) (either l r)

bytes :: [Word8] -> Builder
bytes = mconcat . map B.word8

primFixed :: FixedPrim a -> a -> Builder
primFixed (FixedPrim _ e) = bytes . e

primBounded :: BoundedPrim a -> a -> Builder
primBounded (BoundedPrim _ e) = bytes . e

primMapListFixed :: FixedPrim a -> [a] -> Builder
primMapListFixed p = mconcat . map (primFixed p)

primMapListBounded :: BoundedPrim a -> [a] -> Builder
primMapListBounded p = mconcat . map (primBounded p)

char7 :: FixedPrim Char
char7 = FixedPrim 1 (\c -> [fromIntegral (ord c .&. 0x7F)])

char8 :: FixedPrim Char
char8 = FixedPrim 1 (\c -> [fromIntegral (ord c .&. 0xFF)])

charUtf8 :: BoundedPrim Char
charUtf8 = BoundedPrim 4 (map fromIntegral . utf8 . ord)
  where
    utf8 c
      | c < 0x80 = [c]
      | c < 0x800 = [0xC0 .|. shiftR c 6, 0x80 .|. (c .&. 0x3F)]
      | c < 0x10000 = [0xE0 .|. shiftR c 12, 0x80 .|. (shiftR c 6 .&. 0x3F), 0x80 .|. (c .&. 0x3F)]
      | otherwise = [0xF0 .|. shiftR c 18, 0x80 .|. (shiftR c 12 .&. 0x3F),
                     0x80 .|. (shiftR c 6 .&. 0x3F), 0x80 .|. (c .&. 0x3F)]

word8 :: FixedPrim Word8
word8 = FixedPrim 1 (\w -> [w])

int8 :: FixedPrim Int8
int8 = FixedPrim 1 (\i -> [fromIntegral i])

be, le :: Int -> Integer -> [Word8]
be n x = [ fromIntegral (shiftR x (8 * k) .&. 0xFF) | k <- reverse [0 .. n - 1] ]
le n x = reverse (be n x)

word16BE, word16LE :: FixedPrim Word16
word16BE = FixedPrim 2 (be 2 . toInteger)
word16LE = FixedPrim 2 (le 2 . toInteger)

word32BE, word32LE :: FixedPrim Word32
word32BE = FixedPrim 4 (be 4 . toInteger)
word32LE = FixedPrim 4 (le 4 . toInteger)

word64BE, word64LE :: FixedPrim Word64
word64BE = FixedPrim 8 (be 8 . toInteger)
word64LE = FixedPrim 8 (le 8 . toInteger)

-- | Lowercase hexadecimal, all the digits (leading zeros).
hexFixed :: Int -> Integer -> [Word8]
hexFixed n x = [ fromIntegral (ord (intToDigit (fromInteger (shiftR x (4 * k) .&. 0xF))))
               | k <- reverse [0 .. n - 1] ]

word8HexFixed :: FixedPrim Word8
word8HexFixed = FixedPrim 2 (hexFixed 2 . toInteger)

word16HexFixed :: FixedPrim Word16
word16HexFixed = FixedPrim 4 (hexFixed 4 . toInteger)

word32HexFixed :: FixedPrim Word32
word32HexFixed = FixedPrim 8 (hexFixed 8 . toInteger)

-- Integer's shiftR is arithmetic: a negative value's bytes are its
-- two's complement.
int16BE, int16LE :: FixedPrim Int16
int16BE = FixedPrim 2 (be 2 . toInteger)
int16LE = FixedPrim 2 (le 2 . toInteger)

int32BE, int32LE :: FixedPrim Int32
int32BE = FixedPrim 4 (be 4 . toInteger)
int32LE = FixedPrim 4 (le 4 . toInteger)

int64BE, int64LE :: FixedPrim Int64
int64BE = FixedPrim 8 (be 8 . toInteger)
int64LE = FixedPrim 8 (le 8 . toInteger)

-- Host byte order: little-endian (x86-64, AArch64); Int and Word are 64 bits.
intHost :: FixedPrim Int
intHost = FixedPrim 8 (le 8 . toInteger)
int16Host :: FixedPrim Int16
int16Host = int16LE
int32Host :: FixedPrim Int32
int32Host = int32LE
int64Host :: FixedPrim Int64
int64Host = int64LE
wordHost :: FixedPrim Word
wordHost = FixedPrim 8 (le 8 . toInteger)
word16Host :: FixedPrim Word16
word16Host = word16LE
word32Host :: FixedPrim Word32
word32Host = word32LE
word64Host :: FixedPrim Word64
word64Host = word64LE

primMapByteStringBounded :: BoundedPrim Word8 -> S.ByteString -> Builder
primMapByteStringBounded p = primMapListBounded p . S.unpack

primMapLazyByteStringBounded :: BoundedPrim Word8 -> L.ByteString -> Builder
primMapLazyByteStringBounded p = primMapListBounded p . L.unpack
