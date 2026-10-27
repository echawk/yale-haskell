-- Data.ByteString (bytestring): ByteStrings as Word8s; the Char8
-- functions with the bytes converted (Data.ByteString.Rep).
module Data.ByteString (
    ByteString, mapAccumL, mapAccumR, pack, unpack, empty, singleton, cons, snoc, append, head,
    last, tail, init, uncons, unsnoc, null, length, map, reverse,
    intercalate, intersperse, transpose, foldl, foldl', foldl1, foldr, foldr',
    sort,
    foldr1, concat, concatMap, any, all, maximum, minimum, replicate,
    unfoldr, unfoldrN, take, takeEnd, drop, dropEnd, splitAt, takeWhile,
    takeWhileEnd, dropWhile, dropWhileEnd, span, spanEnd, break, breakEnd,
    breakSubstring, group, groupBy, inits, tails, split, splitWith,
    isPrefixOf, isSuffixOf, isInfixOf, stripPrefix, stripSuffix, elem,
    notElem, find, filter, partition, index, indexMaybe, (!?), elemIndex,
    elemIndices, findIndex, findIndices, count, zip, zipWith, unzip, copy,
    fromStrict, toStrict, fromChunks, toChunks,
    putStr, getLine, getContents, interact, readFile, writeFile,
    appendFile, hPutStr, hPut, hGetLine, hGetContents, hGet, hGetSome,
    hGetNonBlocking
      , packCString, packCStringLen, useAsCString, useAsCStringLen
  ) where

import Prelude hiding (head, last, tail, init, null, length, map, reverse,
                       foldl, foldl1, foldr, foldr1, concat, concatMap, any,
                       all, maximum, minimum, replicate, take, drop,
                       splitAt, takeWhile, dropWhile, span, break, elem,
                       notElem, filter, zip, zipWith, unzip, putStr,
                       getLine, getContents, interact, readFile, writeFile,
                       appendFile)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.ByteString.Char8 as C
import Data.ByteString.Char8 (empty, append, tail, init, null, length,
         reverse, intercalate, transpose, concat, take, takeEnd, drop,
         dropEnd, splitAt, breakSubstring, group, inits, tails, isPrefixOf,
         isSuffixOf, isInfixOf, stripPrefix, stripSuffix, copy, fromStrict,
         toStrict, fromChunks, toChunks, putStr, getLine, getContents,
         interact, readFile, writeFile, appendFile, hPutStr, hPut,
         hGetLine, hGetContents, hGet, hGetSome, hGetNonBlocking)
import Data.ByteString.Rep
import Data.Word (Word8)
import Foreign.C.String (CString, CStringLen)
import Foreign.Ptr (Ptr, castPtr, plusPtr)
import Foreign.Storable (peek, pokeByteOff)
import Foreign.Marshal.Array (peekArray)
import Foreign.Marshal.Alloc (allocaBytes)

infixl 9 !?

pack :: [Word8] -> ByteString
pack ws = C.pack (P.map w2c ws)

unpack :: ByteString -> [Word8]
unpack b = P.map c2w (C.unpack b)

onW :: (Word8 -> a) -> Char -> a
onW f c = f (c2w c)

singleton :: Word8 -> ByteString
singleton = C.singleton . w2c

cons :: Word8 -> ByteString -> ByteString
cons w = C.cons (w2c w)

snoc :: ByteString -> Word8 -> ByteString
snoc b w = C.snoc b (w2c w)

head, last :: ByteString -> Word8
head = c2w . C.head
last = c2w . C.last

uncons :: ByteString -> Maybe (Word8, ByteString)
uncons b = fmap (\(c, r) -> (c2w c, r)) (C.uncons b)

unsnoc :: ByteString -> Maybe (ByteString, Word8)
unsnoc b = fmap (\(r, c) -> (r, c2w c)) (C.unsnoc b)

map :: (Word8 -> Word8) -> ByteString -> ByteString
map f = C.map (w2c . onW f)

intersperse :: Word8 -> ByteString -> ByteString
intersperse w = C.intersperse (w2c w)

foldl, foldl' :: (a -> Word8 -> a) -> a -> ByteString -> a
foldl f = C.foldl (\a c -> f a (c2w c))
foldl' f = C.foldl' (\a c -> f a (c2w c))

foldr, foldr' :: (Word8 -> a -> a) -> a -> ByteString -> a
foldr f = C.foldr (onW f)
foldr' f = C.foldr' (onW f)

-- | The bytes in order.
sort :: ByteString -> ByteString
sort = pack . L.sort . unpack

foldl1, foldr1 :: (Word8 -> Word8 -> Word8) -> ByteString -> Word8
foldl1 f b = P.foldl1 f (unpack b)
foldr1 f b = P.foldr1 f (unpack b)

concatMap :: (Word8 -> ByteString) -> ByteString -> ByteString
concatMap f = C.concatMap (onW f)

any, all :: (Word8 -> Bool) -> ByteString -> Bool
any p = C.any (onW p)
all p = C.all (onW p)

maximum, minimum :: ByteString -> Word8
maximum = c2w . C.maximum
minimum = c2w . C.minimum

replicate :: Int -> Word8 -> ByteString
replicate n w = C.replicate n (w2c w)

unfoldr :: (a -> Maybe (Word8, a)) -> a -> ByteString
unfoldr f = C.unfoldr (\s -> fmap (\(w, s') -> (w2c w, s')) (f s))

-- | At most N bytes, and the seed left (Nothing when F ended it).
unfoldrN :: Int -> (a -> Maybe (Word8, a)) -> a -> (ByteString, Maybe a)
unfoldrN n f s0 = go n s0 []
  where
    go k s acc
      | k <= 0 = (C.pack (P.reverse acc), Just s)
      | otherwise = case f s of
          Nothing -> (C.pack (P.reverse acc), Nothing)
          Just (w, s') -> go (k - 1) s' (w2c w : acc)

takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, filter
  :: (Word8 -> Bool) -> ByteString -> ByteString
takeWhile p = C.takeWhile (onW p)
takeWhileEnd p = C.takeWhileEnd (onW p)
dropWhile p = C.dropWhile (onW p)
dropWhileEnd p = C.dropWhileEnd (onW p)
filter p = C.filter (onW p)

span, spanEnd, break, breakEnd
  :: (Word8 -> Bool) -> ByteString -> (ByteString, ByteString)
span p = C.span (onW p)
spanEnd p = C.spanEnd (onW p)
break p = C.break (onW p)
breakEnd p = C.breakEnd (onW p)

groupBy :: (Word8 -> Word8 -> Bool) -> ByteString -> [ByteString]
groupBy f = C.groupBy (\a b -> f (c2w a) (c2w b))

split :: Word8 -> ByteString -> [ByteString]
split w = C.split (w2c w)

splitWith :: (Word8 -> Bool) -> ByteString -> [ByteString]
splitWith p = C.splitWith (onW p)

elem, notElem :: Word8 -> ByteString -> Bool
elem w = C.elem (w2c w)
notElem w = C.notElem (w2c w)

find :: (Word8 -> Bool) -> ByteString -> Maybe Word8
find p b = fmap c2w (C.find (onW p) b)

partition :: (Word8 -> Bool) -> ByteString -> (ByteString, ByteString)
partition p = C.partition (onW p)

index :: ByteString -> Int -> Word8
index b n = c2w (C.index b n)

indexMaybe, (!?) :: ByteString -> Int -> Maybe Word8
indexMaybe b n = fmap c2w (C.indexMaybe b n)
(!?) = indexMaybe

elemIndex :: Word8 -> ByteString -> Maybe Int
elemIndex w = C.elemIndex (w2c w)

elemIndices :: Word8 -> ByteString -> [Int]
elemIndices w = C.elemIndices (w2c w)

findIndex :: (Word8 -> Bool) -> ByteString -> Maybe Int
findIndex p = C.findIndex (onW p)

findIndices :: (Word8 -> Bool) -> ByteString -> [Int]
findIndices p = C.findIndices (onW p)

count :: Word8 -> ByteString -> Int
count w = C.count (w2c w)

zip :: ByteString -> ByteString -> [(Word8, Word8)]
zip a b = P.zip (unpack a) (unpack b)

zipWith :: (Word8 -> Word8 -> a) -> ByteString -> ByteString -> [a]
zipWith f a b = P.zipWith f (unpack a) (unpack b)

unzip :: [(Word8, Word8)] -> (ByteString, ByteString)
unzip ps = (pack (P.map fst ps), pack (P.map snd ps))

mapAccumL, mapAccumR :: (acc -> Word8 -> (acc, Word8)) -> acc -> ByteString -> (acc, ByteString)
mapAccumL f acc b = case L.mapAccumL f acc (unpack b) of (a, xs) -> (a, pack xs)
mapAccumR f acc b = case L.mapAccumR f acc (unpack b) of (a, xs) -> (a, pack xs)
