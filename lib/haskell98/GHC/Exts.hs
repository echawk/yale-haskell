{-# LANGUAGE MagicHash #-}
-- GHC.Exts (base) for MagicHash programs.  Yale Haskell has no unboxed
-- types: Int# is Int, Double# is Double, and so on; the boxing
-- constructors I#, D#, ... are the identity (parser/exp-parser.mumble),
-- and the primops are the ordinary operations.  A comparison primop
-- returns 1 or 0, as GHC's do, for isTrue#.
module GHC.Exts (
    Int#, Word#, Double#, Float#, Char#, Addr#, Int8#, Int16#, Int32#,
    Int64#, Word8#, Word16#, Word32#, Word64#,
    addrLit#, indexInt8OffAddr#, indexInt16OffAddr#, indexInt32OffAddr#,
    indexIntOffAddr#, indexWord8OffAddr#, indexWord16OffAddr#,
    indexWord32OffAddr#, indexCharOffAddr#,
    int8ToInt#, int16ToInt#, int32ToInt#, int64ToInt#, intToInt8#,
    intToInt16#, intToInt32#, word8ToWord#, word16ToWord#, word32ToWord#,
    wordToWord8#, wordToWord16#, wordToWord32#, int32ToWord32#,
    word32ToInt32#, int16ToWord16#, word16ToInt16#, byteSwap16#,
    byteSwap32#, tagToEnum#, dataToTag#, unsafeCoerce#,
    (+#), (-#), (*#), quotInt#, remInt#, negateInt#, (==#), (/=#), (<#),
    (<=#), (>#), (>=#), isTrue#, andI#, orI#, xorI#, notI#,
    uncheckedIShiftL#, uncheckedIShiftRA#, uncheckedIShiftRL#,
    iShiftL#, iShiftRA#, iShiftRL#, uncheckedShiftL#, uncheckedShiftRL#,
    narrow8Int#, narrow16Int#, narrow32Int#, narrow8Word#, narrow16Word#,
    narrow32Word#, Any,
    (+##), (-##), (*##), (/##), (**##), (==##), (/=##), (<##), (<=##),
    (>##), (>=##), negateDouble#, sqrtDouble#, expDouble#, logDouble#,
    sinDouble#, cosDouble#, int2Double#, double2Int#,
    plusWord#, minusWord#, timesWord#, and#, or#, xor#, not#, shiftL#,
    shiftRL#, int2Word#, word2Int#, eqWord#, ltWord#,
    chr#, ord#, eqChar#, neChar#,
    lazy, inline, oneShot, seq, seq#, build, augment,
    IsList(fromList, toList, fromListN), IsString(fromString)
  ) where

import GHC.IsList (IsList(fromList, toList, fromListN))

import Data.Bits
import Data.Word (Word)
import Data.String (IsString(fromString))
import Data.Array (Array, listArray, (!))
import Unsafe.Coerce (unsafeCoerce)

infixl 7 *#, `quotInt#`, `remInt#`, *##, /##
infixl 6 +#, -#, +##, -##
infix 4 ==#, /=#, <#, <=#, >#, >=#, ==##, /=##, <##, <=##, >##, >=##

type Int# = Int
type Word# = Word
type Double# = Double
type Float# = Float
type Char# = Char
type Int8# = Int
type Int16# = Int
type Int32# = Int
type Int64# = Int
type Word8# = Word
type Word16# = Word
type Word32# = Word
type Word64# = Word

-- An Addr# literal ("..."#, lexer.mumble): its bytes, in an array made
-- once (the literals are top-level tables in Happy's and Alex's code).
newtype Addr# = Addr# (Array Int Int)

addrLit# :: String -> Addr#
addrLit# s = Addr# (listArray (0, length s - 1) (map fromEnum s))

byteAt :: Addr# -> Int -> Int
byteAt (Addr# a) i = a ! i

-- little-endian, as on the machines Yale Haskell runs on
unsignedAt :: Addr# -> Int -> Int -> Int
unsignedAt a size i = go (size - 1) 0
  where base = i * size
        go k acc | k < 0 = acc
                 | otherwise = go (k - 1) (acc * 256 + byteAt a (base + k))

signed :: Int -> Int -> Int
signed bits n = if n >= 2 ^ (bits - 1) then n - 2 ^ bits else n

indexInt8OffAddr#, indexInt16OffAddr#, indexInt32OffAddr#, indexIntOffAddr#
  :: Addr# -> Int -> Int
indexInt8OffAddr# a i = signed 8 (unsignedAt a 1 i)
indexInt16OffAddr# a i = signed 16 (unsignedAt a 2 i)
indexInt32OffAddr# a i = signed 32 (unsignedAt a 4 i)
indexIntOffAddr# a i = signed 64 (unsignedAt a 8 i)

indexWord8OffAddr#, indexWord16OffAddr#, indexWord32OffAddr# :: Addr# -> Int -> Word
indexWord8OffAddr# a i = fromIntegral (unsignedAt a 1 i)
indexWord16OffAddr# a i = fromIntegral (unsignedAt a 2 i)
indexWord32OffAddr# a i = fromIntegral (unsignedAt a 4 i)

indexCharOffAddr# :: Addr# -> Int -> Char
indexCharOffAddr# a i = toEnum (byteAt a i)

int8ToInt#, int16ToInt#, int32ToInt#, int64ToInt#, intToInt8#, intToInt16#,
  intToInt32# :: Int -> Int
int8ToInt# n = n
int16ToInt# n = n
int32ToInt# n = n
int64ToInt# n = n
intToInt8# n = signed 8 (n `mod` 256)
intToInt16# n = signed 16 (n `mod` 65536)
intToInt32# n = signed 32 (n `mod` 4294967296)

word8ToWord#, word16ToWord#, word32ToWord#, wordToWord8#, wordToWord16#,
  wordToWord32# :: Word -> Word
word8ToWord# w = w
word16ToWord# w = w
word32ToWord# w = w
wordToWord8# w = w `mod` 256
wordToWord16# w = w `mod` 65536
wordToWord32# w = w `mod` 4294967296

int32ToWord32#, int16ToWord16# :: Int -> Word
int32ToWord32# n = fromIntegral (n `mod` 4294967296)
int16ToWord16# n = fromIntegral (n `mod` 65536)

word32ToInt32#, word16ToInt16# :: Word -> Int
word32ToInt32# w = signed 32 (fromIntegral w)
word16ToInt16# w = signed 16 (fromIntegral w)

byteSwap16#, byteSwap32# :: Word -> Word
byteSwap16# w = (w `mod` 256) * 256 + (w `div` 256) `mod` 256
byteSwap32# w = sum [((w `div` (256 ^ k)) `mod` 256) * 256 ^ (3 - k) | k <- [0 .. 3 :: Int]]

-- Happy uses it at Bool: (tagToEnum# (n <# m)) :: Bool
tagToEnum# :: Int -> Bool
tagToEnum# n = n /= 0

dataToTag# :: a -> Int
dataToTag# _ = error "GHC.Exts.dataToTag#: not supported"

unsafeCoerce# :: a -> b
unsafeCoerce# = unsafeCoerce

b2i :: Bool -> Int
b2i b = if b then 1 else 0

(+#), (-#), (*#), quotInt#, remInt#, andI#, orI#, xorI# :: Int -> Int -> Int
(+#) = (+)
(-#) = (-)
(*#) = (*)
quotInt# = quot
remInt# = rem
andI# = (.&.)
orI# = (.|.)
xorI# = xor

negateInt#, notI# :: Int -> Int
negateInt# = negate
notI# = complement

(==#), (/=#), (<#), (<=#), (>#), (>=#) :: Int -> Int -> Int
a ==# b = b2i (a == b)
a /=# b = b2i (a /= b)
a <# b = b2i (a < b)
a <=# b = b2i (a <= b)
a ># b = b2i (a > b)
a >=# b = b2i (a >= b)

isTrue# :: Int -> Bool
isTrue# n = n /= 0

uncheckedIShiftL#, uncheckedIShiftRA#, uncheckedIShiftRL# :: Int -> Int -> Int
uncheckedIShiftL# = shiftL
uncheckedIShiftRA# = shiftR
uncheckedIShiftRL# a n = if a >= 0 then shiftR a n else shiftR a n

(+##), (-##), (*##), (/##), (**##) :: Double -> Double -> Double
(+##) = (+)
(-##) = (-)
(*##) = (*)
(/##) = (/)
(**##) = (**)

(==##), (/=##), (<##), (<=##), (>##), (>=##) :: Double -> Double -> Int
a ==## b = b2i (a == b)
a /=## b = b2i (a /= b)
a <## b = b2i (a < b)
a <=## b = b2i (a <= b)
a >## b = b2i (a > b)
a >=## b = b2i (a >= b)

negateDouble#, sqrtDouble#, expDouble#, logDouble#, sinDouble#,
  cosDouble# :: Double -> Double
negateDouble# = negate
sqrtDouble# = sqrt
expDouble# = exp
logDouble# = log
sinDouble# = sin
cosDouble# = cos

int2Double# :: Int -> Double
int2Double# = fromIntegral

double2Int# :: Double -> Int
double2Int# = truncate

plusWord#, minusWord#, timesWord#, and#, or#, xor# :: Word -> Word -> Word
plusWord# = (+)
minusWord# = (-)
timesWord# = (*)
and# = (.&.)
or# = (.|.)
xor# = xor

not# :: Word -> Word
not# = complement

-- Happy's array templates use these (GHC.Base's names)
iShiftL#, iShiftRA#, iShiftRL# :: Int -> Int -> Int
iShiftL# = uncheckedIShiftL#
iShiftRA# = uncheckedIShiftRA#
iShiftRL# = uncheckedIShiftRL#

uncheckedShiftL#, uncheckedShiftRL# :: Word -> Int -> Word
uncheckedShiftL# = shiftL
uncheckedShiftRL# = shiftR

narrow8Int#, narrow16Int#, narrow32Int# :: Int -> Int
narrow8Int# n = signed 8 (n `mod` 256)
narrow16Int# n = signed 16 (n `mod` 65536)
narrow32Int# n = signed 32 (n `mod` 4294967296)

narrow8Word#, narrow16Word#, narrow32Word# :: Word -> Word
narrow8Word# w = w `mod` 256
narrow16Word# w = w `mod` 65536
narrow32Word# w = w `mod` 4294967296

-- GHC's Any (of any kind; here kind *): a value of it is only coerced to
-- and from other types
data Any

shiftL#, shiftRL# :: Word -> Int -> Word
shiftL# = shiftL
shiftRL# = shiftR

int2Word# :: Int -> Word
int2Word# = fromIntegral

word2Int# :: Word -> Int
word2Int# = fromIntegral

eqWord#, ltWord# :: Word -> Word -> Int
eqWord# a b = b2i (a == b)
ltWord# a b = b2i (a < b)

chr# :: Int -> Char
chr# = toEnum

ord# :: Char -> Int
ord# = fromEnum

eqChar#, neChar# :: Char -> Char -> Int
eqChar# a b = b2i (a == b)
neChar# a b = b2i (a /= b)

lazy, inline, oneShot :: a -> a
lazy x = x
inline x = x
oneShot x = x

seq# :: a -> s -> (s, a)
seq# a s = a `seq` (s, a)

build :: ((a -> [a] -> [a]) -> [a] -> [a]) -> [a]
build g = g (:) []

augment :: ((a -> [a] -> [a]) -> [a] -> [a]) -> [a] -> [a]
augment g xs = g (:) xs
