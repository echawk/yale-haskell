-- Data.Binary (binary): the Binary class with binary's encodings, so
-- that what GHC programs wrote decodes here and the other way round:
-- Int, Word and Int64 as 8 bytes big-endian, Integer and Natural tagged
-- (small, or sign and bytes), Char as UTF-8, a list or container as its
-- length then its elements, Float and Double through decodeFloat.
-- There are no Generic default methods (Yale Haskell has no Generic
-- representations): an instance gives put and get.
module Data.Binary (
    Binary(put, get, putList), encode, decode, decodeOrFail, encodeFile,
    decodeFile, decodeFileOrFail,
    Get, Put, putWord8, getWord8, Word8, Word16, Word32, Word64,
    module Data.Binary.Get, module Data.Binary.Put
  ) where

import Data.Binary.Get (Get, runGetOrFail, ByteOffset, getWord8, getWord16be,
                        getWord32be, getWord64be, getInt8, getInt16be,
                        getInt32be, getInt64be, getByteString, getBytesString)
import Data.Binary.Put (Put, PutM, runPut, putWord8, putWord16be, putWord32be,
                        putWord64be, putInt8, putInt16be, putInt32be,
                        putInt64be, putByteString, putCharUtf8)
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.ByteString.Internal (unBS, bsFromString)
import qualified Data.ByteString.Lazy.Internal as LI
import Data.Int
import Data.Word
import Data.Char (chr, ord)
import Data.Bits ((.&.), (.|.), shiftL)
import Data.Ratio (Ratio, (%), numerator, denominator)
import Data.List.NonEmpty (NonEmpty((:|)))
import qualified Data.List.NonEmpty as NE
import Numeric.Natural (Natural)
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Data.IntMap as IntMap
import qualified Data.IntSet as IntSet
import qualified Data.Sequence as Seq
import qualified Data.Tree as Tree
import Data.Array (Array, Ix, bounds, elems, listArray)
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Encoding as TE
import qualified Data.Foldable as F

class Binary t where
  put :: t -> Put
  get :: Get t
  putList :: [t] -> Put
  putList xs = put (length xs) >> mapM_ put xs

encode :: Binary a => a -> L.ByteString
encode = runPut . put

decode :: Binary a => L.ByteString -> a
decode b = case runGetOrFail get b of
  Right (_, _, a) -> a
  Left (_, n, msg) -> error ("Data.Binary.decode at position " ++ show n ++ ": " ++ msg)

decodeOrFail :: Binary a => L.ByteString
             -> Either (L.ByteString, ByteOffset, String) (L.ByteString, ByteOffset, a)
decodeOrFail = runGetOrFail get

encodeFile :: Binary a => FilePath -> a -> IO ()
encodeFile f v = L.writeFile f (encode v)

decodeFile :: Binary a => FilePath -> IO a
decodeFile f = fmap decode (L.readFile f)

decodeFileOrFail :: Binary a => FilePath -> IO (Either (ByteOffset, String) a)
decodeFileOrFail f = do
  b <- L.readFile f
  return (case decodeOrFail b of
            Right (_, _, a) -> Right a
            Left (_, n, msg) -> Left (n, msg))

instance Binary () where
  put () = return ()
  get = return ()

instance Binary Bool where
  put b = putWord8 (if b then 1 else 0)
  get = getWord8 >>= \w -> case w of
    0 -> return False
    1 -> return True
    _ -> fail ("Could not map value " ++ show w ++ " to Bool")

instance Binary Ordering where
  put o = putWord8 (fromIntegral (fromEnum o))
  get = getWord8 >>= \w -> if w <= 2 then return (toEnum (fromIntegral w))
                           else fail ("Could not map value " ++ show w ++ " to Ordering")

instance Binary Word8 where { put = putWord8; get = getWord8 }
instance Binary Word16 where { put = putWord16be; get = getWord16be }
instance Binary Word32 where { put = putWord32be; get = getWord32be }
instance Binary Word64 where { put = putWord64be; get = getWord64be }
instance Binary Int8 where { put = putInt8; get = getInt8 }
instance Binary Int16 where { put = putInt16be; get = getInt16be }
instance Binary Int32 where { put = putInt32be; get = getInt32be }
instance Binary Int64 where { put = putInt64be; get = getInt64be }

instance Binary Word where
  put = putWord64be . fromIntegral
  get = fmap fromIntegral getWord64be

instance Binary Int where
  put = putInt64be . fromIntegral
  get = fmap fromIntegral getInt64be

-- tag 0 and an Int32 when it fits, else tag 1, the sign and the bytes
-- (least significant first, as a list)
instance Binary Integer where
  put n | n >= toInteger (minBound :: Int32) && n <= toInteger (maxBound :: Int32) =
            putWord8 0 >> put (fromInteger n :: Int32)
        | otherwise = do
            putWord8 1
            put (if n < 0 then 0 else 1 :: Word8)
            put (unroll (abs n))
  get = getWord8 >>= \tag -> case tag of
    0 -> fmap (toInteger :: Int32 -> Integer) get
    _ -> do
      sign <- get :: Get Word8
      bytes <- get
      let v = roll bytes
      return (if sign == 1 then v else negate v)

unroll :: Integer -> [Word8]
unroll 0 = []
unroll n = fromInteger (n `mod` 256) : unroll (n `div` 256)

roll :: [Word8] -> Integer
roll = foldr (\b acc -> acc * 256 + toInteger b) 0

instance Binary Natural where
  put n | n <= fromIntegral (maxBound :: Word64) = putWord8 0 >> put (fromIntegral n :: Word64)
        | otherwise = putWord8 1 >> put (unroll (toInteger n))
  get = getWord8 >>= \tag -> case tag of
    0 -> fmap (fromIntegral :: Word64 -> Natural) get
    _ -> fmap (fromInteger . roll) get

instance (Binary a, Integral a) => Binary (Ratio a) where
  put r = put (numerator r) >> put (denominator r)
  get = do { n <- get; d <- get; return (n % d) }

instance Binary Char where
  put = putCharUtf8
  get = do
    w <- getWord8
    let b = fromIntegral w :: Int
        cont = fmap (\x -> fromIntegral x .&. 0x3F) getWord8
        more k acc = if k == (0 :: Int) then return acc
                     else cont >>= \c -> more (k - 1) (shiftL acc 6 .|. c)
    n <- if b < 0x80 then return b
         else if b < 0xE0 then more 1 (b .&. 0x1F)
         else if b < 0xF0 then more 2 (b .&. 0x0F)
         else more 3 (b .&. 0x07)
    return (chr n)
  putList s = put (length s) >> mapM_ put s

instance Binary Float where
  put d = put (decodeFloat d)
  get = do { (m, e) <- get; return (encodeFloat m e) }

instance Binary Double where
  put d = put (decodeFloat d)
  get = do { (m, e) <- get; return (encodeFloat m e) }

instance Binary a => Binary [a] where
  put = putList
  get = do { n <- get :: Get Int; getMany n }

getMany :: Binary a => Int -> Get [a]
getMany n = go n []
  where go 0 acc = return (reverse acc)
        go k acc = get >>= \x -> x `seq` go (k - 1) (x : acc)

instance Binary a => Binary (Maybe a) where
  put Nothing = putWord8 0
  put (Just x) = putWord8 1 >> put x
  get = getWord8 >>= \w -> case w of
    0 -> return Nothing
    _ -> fmap Just get

instance (Binary a, Binary b) => Binary (Either a b) where
  put (Left a) = putWord8 0 >> put a
  put (Right b) = putWord8 1 >> put b
  get = getWord8 >>= \w -> case w of
    0 -> fmap Left get
    _ -> fmap Right get

instance (Binary a, Binary b) => Binary (a, b) where
  put (a, b) = put a >> put b
  get = do { a <- get; b <- get; return (a, b) }
instance (Binary a, Binary b, Binary c) => Binary (a, b, c) where
  put (a, b, c) = put a >> put b >> put c
  get = do { a <- get; b <- get; c <- get; return (a, b, c) }
instance (Binary a, Binary b, Binary c, Binary d) => Binary (a, b, c, d) where
  put (a, b, c, d) = put a >> put b >> put c >> put d
  get = do { a <- get; b <- get; c <- get; d <- get; return (a, b, c, d) }
instance (Binary a, Binary b, Binary c, Binary d, Binary e) => Binary (a, b, c, d, e) where
  put (a, b, c, d, e) = put a >> put b >> put c >> put d >> put e
  get = do { a <- get; b <- get; c <- get; d <- get; e <- get; return (a, b, c, d, e) }
instance (Binary a, Binary b, Binary c, Binary d, Binary e, Binary f)
      => Binary (a, b, c, d, e, f) where
  put (a, b, c, d, e, f) = put a >> put b >> put c >> put d >> put e >> put f
  get = do { a <- get; b <- get; c <- get; d <- get; e <- get; f <- get
           ; return (a, b, c, d, e, f) }

instance Binary a => Binary (NonEmpty a) where
  put = put . NE.toList
  get = get >>= \xs -> case xs of
    (x : rest) -> return (x :| rest)
    [] -> fail "NonEmpty is empty!"

instance Binary S.ByteString where
  put b = put (length (unBS b)) >> putByteString b
  get = get >>= getByteString

instance Binary L.ByteString where
  put (LI.LBS b) = put (length (unBS b)) >> putByteString b
  get = do { n <- get; s <- getBytesString n; return (LI.LBS (bsFromString s)) }

-- as the text package's instance: the UTF-8 bytes as a ByteString
instance Binary T.Text where
  put = put . TE.encodeUtf8
  get = fmap TE.decodeUtf8 get

instance Binary TL.Text where
  put = put . TL.toStrict
  get = fmap TL.fromStrict get

instance (Binary k, Binary v) => Binary (Map.Map k v) where
  put m = put (Map.size m) >> mapM_ put (Map.toAscList m)
  get = fmap Map.fromDistinctAscList get

instance Binary a => Binary (Set.Set a) where
  put s = put (Set.size s) >> mapM_ put (Set.toAscList s)
  get = fmap Set.fromDistinctAscList get

instance Binary v => Binary (IntMap.IntMap v) where
  put m = put (IntMap.size m) >> mapM_ put (IntMap.toAscList m)
  get = fmap IntMap.fromDistinctAscList get

instance Binary IntSet.IntSet where
  put s = put (IntSet.size s) >> mapM_ put (IntSet.toAscList s)
  get = fmap IntSet.fromDistinctAscList get

instance Binary a => Binary (Seq.Seq a) where
  put s = put (Seq.length s) >> mapM_ put (F.toList s)
  get = fmap Seq.fromList get

instance Binary a => Binary (Tree.Tree a) where
  put (Tree.Node r cs) = put r >> put cs
  get = do { r <- get; cs <- get; return (Tree.Node r cs) }

instance (Binary i, Ix i, Binary e) => Binary (Array i e) where
  put a = put (bounds a) >> put (length (elems a)) >> mapM_ put (elems a)
  get = do { bs <- get; n <- get; xs <- getMany n; return (listArray bs xs) }
