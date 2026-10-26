{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns, UnboxedTuples #-}
-- GHC.Exts (base) for MagicHash programs.  Yale Haskell has no unboxed
-- types: Int# is Int, Double# is Double, and so on; the boxing
-- constructors I#, D#, ... are the identity (parser/exp-parser.mumble),
-- and the primops are the ordinary operations.  A comparison primop
-- returns 1 or 0, as GHC's do, for isTrue#.
module GHC.Exts (
    Int, Word, Char, Double, Float, Constraint, reallyUnsafePtrEquality#,
    Int#, Word#, Double#, Float#, Char#, Addr#, Int8#, Int16#, Int32#,
    Int64#, Word8#, Word16#, Word32#, Word64#,
    unpackCString#, unpackAppendCString#, unpackFoldrCString#,
    unpackCStringUtf8#, unpackAppendCStringUtf8#, unpackFoldrCStringUtf8#,
    unpackNBytes#, cstringLength#,
    addrLit#, indexInt8OffAddr#, indexInt16OffAddr#, indexInt32OffAddr#,
    indexIntOffAddr#, indexWord8OffAddr#, indexWord16OffAddr#,
    indexWord32OffAddr#, indexCharOffAddr#,
    int8ToInt#, int16ToInt#, int32ToInt#, int64ToInt#, intToInt8#,
    intToInt16#, intToInt32#, word8ToWord#, word16ToWord#, word32ToWord#,
    wordToWord8#, wordToWord16#, wordToWord32#, int32ToWord32#,
    word32ToInt32#, int16ToWord16#, word16ToInt16#, byteSwap16#,
    byteSwap32#, tagToEnum#, dataToTag#, unsafeCoerce#,
    bitReverse#, bitReverse8#, bitReverse16#, bitReverse32#, bitReverse64#,
    pdep#, pdep8#, pdep16#, pdep32#, pdep64#, pext#, pext8#, pext16#, pext32#, pext64#,
    (+#), (-#), (*#), quotInt#, remInt#, negateInt#, (==#), (/=#), (<#),
    (<=#), (>#), (>=#), isTrue#, andI#, orI#, xorI#, notI#,
    uncheckedIShiftL#, uncheckedIShiftRA#, uncheckedIShiftRL#,
    iShiftL#, iShiftRA#, iShiftRL#, uncheckedShiftL#, uncheckedShiftRL#,
    narrow8Int#, narrow16Int#, narrow32Int#, narrow8Word#, narrow16Word#,
    narrow32Word#, Any,
    (+##), (-##), (*##), (/##), (**##), (==##), (/=##), (<##), (<=##),
    (>##), (>=##), negateDouble#, sqrtDouble#, expDouble#, logDouble#,
    sinDouble#, cosDouble#, int2Double#, double2Int#,
    plusWord#, minusWord#, timesWord#, timesWord2#, plusWord2#, and#, or#, xor#, not#, shiftL#,
    shiftRL#, int2Word#, word2Int#, eqWord#, neWord#, ltWord#, leWord#,
    gtWord#, geWord#,
    chr#, ord#, eqChar#, neChar#, ltChar#, leChar#, gtChar#, geChar#,
    eqFloat#, neFloat#, ltFloat#, leFloat#, gtFloat#, geFloat#,
    eqAddr#, neAddr#, ltAddr#, leAddr#, gtAddr#, geAddr#,
    lazy, inline, oneShot, seq, seq#, build, augment,
    IsList(..), Item, IsString(fromString),
    coerce, Coercible,
    module GHC.PrimOps, module GHC.PrimOpsTyped, UnliftedType, UnliftedRep,
    RuntimeRep(..), Levity(..), TYPE, LiftedRep, SPEC(..),
    Ptr(Ptr), FunPtr(FunPtr), Down(..), sortWith, groupWith, the, realWorld#, runRW#, noDuplicate#, keepAlive#,
    atomicModifyMutVar#, atomicModifyMutVar2#, atomicModifyMutVar_#
  ) where

import GHC.IsList (IsList(..), Item)
import Data.Coerce (coerce, Coercible)
import Data.Kind (Constraint)
import BasePrims (primPtrEq)
import GHC.PrimOps
import GHC.PrimOpsTyped
import Foreign.Ptr (Ptr, FunPtr)
import Data.Ord (Down(..), comparing)
import Data.List (sortBy, groupBy)

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

-- Addr#, its literals ("..."#, lexer.mumble: GHC.Exts.addrLit#) and the
-- operations on memory, arrays and mutable variables are GHC.PrimOps'
-- (src/base/primops-runtime.lisp).

-- the sign of the low BITS bits of N
signed :: Int -> Int -> Int
signed bits n = if n >= 2 ^ (bits - 1) then n - 2 ^ bits else n

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

-- an enumeration's constructor by number: Happy's (tagToEnum# (n <# m)) ::
-- Bool, unicode-data's Block
tagToEnum# :: Enum a => Int -> a
tagToEnum# = toEnum

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

-- the high and low words of the product, and of the sum (its carry)
timesWord2#, plusWord2# :: Word -> Word -> (# Word, Word #)
timesWord2# x y = let p = toInteger x * toInteger y
                  in (# fromInteger (p `div` 18446744073709551616), fromInteger p #)
plusWord2# x y = let p = toInteger x + toInteger y
                 in (# fromInteger (p `div` 18446744073709551616), fromInteger p #)

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

-- A Ptr is an Addr#: both are machine addresses here (GHC.Ptr)
pattern Ptr :: Addr# -> Ptr a
pattern Ptr a <- (unsafeCoerce -> a)
  where Ptr a = unsafeCoerce a

pattern FunPtr :: Addr# -> FunPtr a
pattern FunPtr a <- (unsafeCoerce -> a)
  where FunPtr a = unsafeCoerce a

-- TransformListComp's helpers
sortWith :: Ord b => (a -> b) -> [a] -> [a]
sortWith f = sortBy (comparing f)

groupWith :: Ord b => (a -> b) -> [a] -> [[a]]
groupWith f = groupBy (\x y -> f x == f y) . sortWith f

the :: Eq a => [a] -> a
the (x : xs) | all (== x) xs = x
the _ = error "GHC.Exts.the: empty list or not all equal"

-- kinds (not checked): GHC's unlifted types' kinds
data UnliftedType
data UnliftedRep

-- Representation kinds (levity polymorphism): kinds are inferred and
-- every value is boxed, so these only name things in kind signatures.
data RuntimeRep = BoxedRep Levity | IntRep | WordRep | Int64Rep | Word64Rep
                | AddrRep | FloatRep | DoubleRep
data Levity = Lifted | Unlifted
data TYPE r
data LiftedRep

-- | SpecConstr's hint (a constructor argument keeps a loop specialised);
-- an ordinary type here.
data SPEC = SPEC | SPEC2

shiftL#, shiftRL# :: Word -> Int -> Word
shiftL# = shiftL
shiftRL# = shiftR

int2Word# :: Int -> Word
int2Word# = fromIntegral

word2Int# :: Word -> Int
word2Int# = fromIntegral

eqWord#, neWord#, ltWord#, leWord#, gtWord#, geWord# :: Word -> Word -> Int
eqWord# a b = b2i (a == b)
neWord# a b = b2i (a /= b)
ltWord# a b = b2i (a < b)
leWord# a b = b2i (a <= b)
gtWord# a b = b2i (a > b)
geWord# a b = b2i (a >= b)

chr# :: Int -> Char
chr# = toEnum

ord# :: Char -> Int
ord# = fromEnum

eqChar#, neChar#, ltChar#, leChar#, gtChar#, geChar# :: Char -> Char -> Int
eqChar# a b = b2i (a == b)
neChar# a b = b2i (a /= b)
ltChar# a b = b2i (a < b)
leChar# a b = b2i (a <= b)
gtChar# a b = b2i (a > b)
geChar# a b = b2i (a >= b)

eqFloat#, neFloat#, ltFloat#, leFloat#, gtFloat#, geFloat# :: Float -> Float -> Int
eqFloat# a b = b2i (a == b)
neFloat# a b = b2i (a /= b)
ltFloat# a b = b2i (a < b)
leFloat# a b = b2i (a <= b)
gtFloat# a b = b2i (a > b)
geFloat# a b = b2i (a >= b)

-- an Addr# is its bytes here, so addresses compare by contents
eqAddr#, neAddr#, ltAddr#, leAddr#, gtAddr#, geAddr# :: Addr# -> Addr# -> Int
eqAddr# a b = eqAddrPrim a b
neAddr# a b = 1 - eqAddrPrim a b
ltAddr# a b = ltAddrPrim a b
leAddr# a b = b2i (ltAddrPrim a b == 1 || eqAddrPrim a b == 1)
gtAddr# a b = ltAddrPrim b a
geAddr# a b = b2i (ltAddrPrim a b == 0)

-- The State# token (GHC.PrimOps): realWorld#'s value is never looked at.
realWorld# :: State# RealWorld
realWorld# = unsafeCoerce (0 :: Int)

runRW# :: (State# RealWorld -> o) -> o
runRW# f = f realWorld#

noDuplicate# :: State# s -> State# s
noDuplicate# s = s


-- the new value swapped in with a compare-and-swap (Control.Concurrent's
-- threads).  atomicModifyMutVar2# answers the old value and f's result,
-- whose first component is the new value.
atomicModifyMutVar2# :: MutVar# s a -> (a -> c) -> State# s -> (State# s, a, c)
atomicModifyMutVar2# = atomicModifyMutVar2Prim#

atomicModifyMutVar_# :: MutVar# s a -> (a -> a) -> State# s -> (State# s, a, a)
atomicModifyMutVar_# = atomicModifyMutVar_Prim#

atomicModifyMutVar# :: MutVar# s a -> (a -> b) -> State# s -> (State# s, c)
atomicModifyMutVar# mv f s =
  case atomicModifyMutVar2# mv f s of
    (s1, _, r) -> (s1, case unsafeCoerce r of (_, c) -> c)

keepAlive# :: a -> State# s -> (State# s -> b) -> b
keepAlive# _ s k = k s

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

-- 1 when the arguments are the same object (after evaluating them)
reallyUnsafePtrEquality# :: a -> a -> Int#
reallyUnsafePtrEquality# x y = if primPtrEq x y then 1 else 0

-- GHC.CString's (ghc-prim; GHC.Exts re-exports them, as base >= 4.15
-- does: unicode-data's): C strings at an Addr#
cstrBytes :: Addr# -> [Int]
cstrBytes a = takeWhile (/= 0) [fromIntegral (indexWord8OffAddr# a i) | i <- [0 ..]]

cstringLength# :: Addr# -> Int
cstringLength# a = length (cstrBytes a)

unpackCString# :: Addr# -> [Char]
unpackCString# a = map toEnum (cstrBytes a)

unpackAppendCString# :: Addr# -> [Char] -> [Char]
unpackAppendCString# a rest = unpackCString# a ++ rest

unpackFoldrCString# :: Addr# -> (Char -> b -> b) -> b -> b
unpackFoldrCString# a f z = foldr f z (unpackCString# a)

unpackCStringUtf8# :: Addr# -> [Char]
unpackCStringUtf8# a = decodeUtf8 (cstrBytes a)

unpackAppendCStringUtf8# :: Addr# -> [Char] -> [Char]
unpackAppendCStringUtf8# a rest = unpackCStringUtf8# a ++ rest

unpackFoldrCStringUtf8# :: Addr# -> (Char -> b -> b) -> b -> b
unpackFoldrCStringUtf8# a f z = foldr f z (unpackCStringUtf8# a)

-- | The first N bytes, as Latin-1 Chars.
unpackNBytes# :: Addr# -> Int -> [Char]
unpackNBytes# a n = [toEnum (fromIntegral (indexWord8OffAddr# a i)) | i <- [0 .. n - 1]]

decodeUtf8 :: [Int] -> [Char]
decodeUtf8 [] = []
decodeUtf8 (b : bs)
  | b < 0x80 = toEnum b : decodeUtf8 bs
  | b < 0xE0, (c : r) <- bs = toEnum (((b .&. 0x1F) `shiftL` 6) .|. (c .&. 0x3F)) : decodeUtf8 r
  | b < 0xF0, (c : d : r) <- bs =
      toEnum (((b .&. 0x0F) `shiftL` 12) .|. ((c .&. 0x3F) `shiftL` 6) .|. (d .&. 0x3F)) : decodeUtf8 r
  | (c : d : e : r) <- bs =
      toEnum (((b .&. 0x07) `shiftL` 18) .|. ((c .&. 0x3F) `shiftL` 12) .|. ((d .&. 0x3F) `shiftL` 6) .|. (e .&. 0x3F)) : decodeUtf8 r
  | otherwise = ['\xFFFD']

-- BMI2's parallel bit deposit and extract (bitvec's): the low bits of
-- SRC put at MASK's set bits, and the bits of SRC at MASK's set bits
-- gathered low
pdep#, pext# :: Word -> Word -> Word
pdep# src mask = go src mask 0 0
  where go s m bit acc
          | m == 0 = acc
          | otherwise =
              let low = m .&. negate m
                  acc' = if testBit s bit then acc .|. low else acc
              in go s (m .&. (m - 1)) (bit + 1) acc'
pext# src mask = go mask 0 0
  where go m bit acc
          | m == 0 = acc
          | otherwise =
              let low = m .&. negate m
                  acc' = if src .&. low /= 0 then setBit acc bit else acc
              in go (m .&. (m - 1)) (bit + 1) acc'

pdep8#, pdep16#, pdep32#, pdep64#, pext8#, pext16#, pext32#, pext64# :: Word -> Word -> Word
pdep8# s m = pdep# s (m .&. 0xFF)
pdep16# s m = pdep# s (m .&. 0xFFFF)
pdep32# s m = pdep# s (m .&. 0xFFFFFFFF)
pdep64# = pdep#
pext8# s m = pext# s (m .&. 0xFF)
pext16# s m = pext# s (m .&. 0xFFFF)
pext32# s m = pext# s (m .&. 0xFFFFFFFF)
pext64# = pext#

-- the low N bits of a word in reverse order (bitvec's)
bitReverseN :: Int -> Word -> Word
bitReverseN n w = foldl (\acc i -> if testBit w i then setBit acc (n - 1 - i) else acc) 0 [0 .. n - 1]

bitReverse#, bitReverse8#, bitReverse16#, bitReverse32#, bitReverse64# :: Word -> Word
bitReverse# = bitReverseN 64
bitReverse8# = bitReverseN 8
bitReverse16# = bitReverseN 16
bitReverse32# = bitReverseN 32
bitReverse64# = bitReverseN 64
