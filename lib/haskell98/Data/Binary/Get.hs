-- Data.Binary.Get (binary): decoding bytes.  The input is the bytes of
-- a lazy ByteString as a String of Chars 0..255 (Yale Haskell's
-- ByteStrings are text); the incremental interface (runGetIncremental)
-- collects its input and then decodes it in one piece.
module Data.Binary.Get (
    Get, runGet, runGetOrFail, ByteOffset, Decoder(..), runGetIncremental,
    pushChunk, pushChunks, pushEndOfInput,
    skip, isEmpty, bytesRead, lookAhead, lookAheadM, lookAheadE, label,
    getByteString, getLazyByteString, getLazyByteStringNul,
    getRemainingLazyByteString,
    getWord8, getWord16be, getWord16le, getWord16host, getWord32be,
    getWord32le, getWord32host, getWord64be, getWord64le, getWord64host,
    getWordhost, getInt8, getInt16be, getInt16le, getInt16host, getInt32be,
    getInt32le, getInt32host, getInt64be, getInt64le, getInt64host,
    getInthost, getFloatbe, getFloatle, getFloathost, getDoublebe,
    getDoublele, getDoublehost,
    -- for Data.Binary.Put and Data.Binary
    word32ToFloat, word64ToDouble, getBytesString
  ) where

import PreludeModern (MonadFail(fail))
import Control.Applicative (Applicative(pure, (<*>)), Alternative(empty, (<|>)))
import Control.Monad (MonadPlus(mzero, mplus))
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.ByteString.Rep (unBS, bsFromString)
import qualified Data.ByteString.Lazy.Internal as LI
import Data.Int
import Data.Word
import Data.Char (ord)

type ByteOffset = Int64

-- the rest of the input and its offset, to a result or an error
newtype Get a = Get (String -> Int64 -> Either (String, Int64, String) (a, String, Int64))

unGet :: Get a -> String -> Int64 -> Either (String, Int64, String) (a, String, Int64)
unGet (Get f) = f

instance Functor Get where
  fmap f (Get g) = Get (\s n -> case g s n of
                                  Right (a, s', n') -> Right (f a, s', n')
                                  Left e -> Left e)

instance Applicative Get where
  pure a = Get (\s n -> Right (a, s, n))
  mf <*> ma = mf >>= \f -> fmap f ma

instance Monad Get where
  return = pure
  Get g >>= k = Get (\s n -> case g s n of
                               Right (a, s', n') -> unGet (k a) s' n'
                               Left e -> Left e)

instance MonadFail Get where
  fail msg = Get (\s n -> Left (s, n, msg))

instance Alternative Get where
  empty = fail "Data.Binary.Get(Alternative).empty"
  Get f <|> Get g = Get (\s n -> case f s n of
                                   Left _ -> g s n
                                   r -> r)

instance MonadPlus Get where
  mzero = empty
  mplus = (<|>)

input :: L.ByteString -> String
input (LI.LBS b) = unBS b

runGetOrFail :: Get a -> L.ByteString
             -> Either (L.ByteString, ByteOffset, String) (L.ByteString, ByteOffset, a)
runGetOrFail g lbs = case unGet g (input lbs) 0 of
  Right (a, rest, n) -> Right (lazy rest, n, a)
  Left (rest, n, msg) -> Left (lazy rest, n, msg)

lazy :: String -> L.ByteString
lazy s = LI.LBS (bsFromString s)

runGet :: Get a -> L.ByteString -> a
runGet g lbs = case runGetOrFail g lbs of
  Right (_, _, a) -> a
  Left (_, n, msg) -> error ("Data.Binary.Get.runGet at position " ++ show n ++ ": " ++ msg)

data Decoder a = Fail S.ByteString ByteOffset String
               | Partial (Maybe S.ByteString -> Decoder a)
               | Done S.ByteString ByteOffset a

runGetIncremental :: Get a -> Decoder a
runGetIncremental g = collect []
  where collect acc = Partial (\m -> case m of
          Just c -> collect (unBS c : acc)
          Nothing -> case unGet g (concat (reverse acc)) 0 of
            Right (a, rest, n) -> Done (bsFromString rest) n a
            Left (rest, n, msg) -> Fail (bsFromString rest) n msg)

pushChunk :: Decoder a -> S.ByteString -> Decoder a
pushChunk (Partial k) c = k (Just c)
pushChunk d _ = d

pushChunks :: Decoder a -> L.ByteString -> Decoder a
pushChunks d (LI.LBS b) = pushChunk d b

pushEndOfInput :: Decoder a -> Decoder a
pushEndOfInput (Partial k) = k Nothing
pushEndOfInput d = d

-- n bytes as a String
getBytesString :: Int -> Get String
getBytesString k = Get (\s n -> let (a, b) = splitAt k s in
                                  if length a < k
                                    then Left (s, n, "not enough bytes")
                                    else Right (a, b, n + fromIntegral k))

skip :: Int -> Get ()
skip k = fmap (const ()) (getBytesString k)

isEmpty :: Get Bool
isEmpty = Get (\s n -> Right (null s, s, n))

bytesRead :: Get Int64
bytesRead = Get (\s n -> Right (n, s, n))

lookAhead :: Get a -> Get a
lookAhead g = Get (\s n -> case unGet g s n of
                             Right (a, _, _) -> Right (a, s, n)
                             Left e -> Left e)

lookAheadM :: Get (Maybe a) -> Get (Maybe a)
lookAheadM g = Get (\s n -> case unGet g s n of
                              Right (Nothing, _, _) -> Right (Nothing, s, n)
                              r -> r)

lookAheadE :: Get (Either a b) -> Get (Either a b)
lookAheadE g = Get (\s n -> case unGet g s n of
                              Right (Left a, _, _) -> Right (Left a, s, n)
                              r -> r)

label :: String -> Get a -> Get a
label l g = Get (\s n -> case unGet g s n of
                           Left (s', n', msg) -> Left (s', n', l ++ "\n" ++ msg)
                           r -> r)

getByteString :: Int -> Get S.ByteString
getByteString k = fmap bsFromString (getBytesString k)

getLazyByteString :: Int64 -> Get L.ByteString
getLazyByteString k = fmap lazy (getBytesString (fromIntegral k))

getLazyByteStringNul :: Get L.ByteString
getLazyByteStringNul = Get (\s n -> case break (== '\0') s of
  (a, _ : b) -> Right (lazy a, b, n + fromIntegral (length a) + 1)
  _ -> Left (s, n, "getLazyByteStringNul: no NUL"))

getRemainingLazyByteString :: Get L.ByteString
getRemainingLazyByteString = Get (\s n -> Right (lazy s, [], n + fromIntegral (length s)))

-- the value of k bytes, most significant first
bigEndian :: Int -> Get Integer
bigEndian k = fmap (foldl (\acc c -> acc * 256 + toInteger (ord c)) 0) (getBytesString k)

littleEndian :: Int -> Get Integer
littleEndian k = fmap (foldr (\c acc -> acc * 256 + toInteger (ord c)) 0) (getBytesString k)

getWord8 :: Get Word8
getWord8 = fmap fromInteger (bigEndian 1)
getWord16be, getWord16le, getWord16host :: Get Word16
getWord16be = fmap fromInteger (bigEndian 2)
getWord16le = fmap fromInteger (littleEndian 2)
getWord16host = getWord16le
getWord32be, getWord32le, getWord32host :: Get Word32
getWord32be = fmap fromInteger (bigEndian 4)
getWord32le = fmap fromInteger (littleEndian 4)
getWord32host = getWord32le
getWord64be, getWord64le, getWord64host :: Get Word64
getWord64be = fmap fromInteger (bigEndian 8)
getWord64le = fmap fromInteger (littleEndian 8)
getWord64host = getWord64le
getWordhost :: Get Word
getWordhost = fmap fromIntegral getWord64host

getInt8 :: Get Int8
getInt8 = fmap fromIntegral getWord8
getInt16be, getInt16le, getInt16host :: Get Int16
getInt16be = fmap fromIntegral getWord16be
getInt16le = fmap fromIntegral getWord16le
getInt16host = getInt16le
getInt32be, getInt32le, getInt32host :: Get Int32
getInt32be = fmap fromIntegral getWord32be
getInt32le = fmap fromIntegral getWord32le
getInt32host = getInt32le
getInt64be, getInt64le, getInt64host :: Get Int64
getInt64be = fmap fromIntegral getWord64be
getInt64le = fmap fromIntegral getWord64le
getInt64host = getInt64le
getInthost :: Get Int
getInthost = fmap fromIntegral getInt64host

-- IEEE 754 bits to a value
word32ToFloat :: Word32 -> Float
word32ToFloat w = fromBits 23 8 127 (toInteger w)

word64ToDouble :: Word64 -> Double
word64ToDouble w = fromBits 52 11 1023 (toInteger w)

fromBits :: RealFloat a => Int -> Int -> Int -> Integer -> a
fromBits mbits ebits bias w =
  let m = w `mod` (2 ^ mbits)
      e = fromInteger ((w `div` (2 ^ mbits)) `mod` (2 ^ ebits))
      neg = w >= 2 ^ (mbits + ebits)
      emax = 2 ^ ebits - 1
      mag | e == emax = if m == 0 then 1 / 0 else 0 / 0
          | e == 0 = encodeFloat m (1 - bias - mbits)
          | otherwise = encodeFloat (m + 2 ^ mbits) (e - bias - mbits)
  in if neg then negate mag else mag

getFloatbe, getFloatle, getFloathost :: Get Float
getFloatbe = fmap word32ToFloat getWord32be
getFloatle = fmap word32ToFloat getWord32le
getFloathost = getFloatle
getDoublebe, getDoublele, getDoublehost :: Get Double
getDoublebe = fmap word64ToDouble getWord64be
getDoublele = fmap word64ToDouble getWord64le
getDoublehost = getDoublele
