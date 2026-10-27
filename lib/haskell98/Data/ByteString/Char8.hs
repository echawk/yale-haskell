-- Data.ByteString.Char8 (bytestring): ByteStrings as Chars (Latin-1),
-- over the packed Text (Data.ByteString.Rep): what Data.Text does
-- the same way is delegated to it.
module Data.ByteString.Char8 (
    ByteString, mapAccumL, mapAccumR, pack, unpack, empty, singleton, cons, snoc, append, head,
    last, tail, init, uncons, unsnoc, null, length, map, reverse,
    intercalate, intersperse, transpose, foldl, foldl', foldl1, foldr,
    foldr', foldr1, concat, concatMap, any, all, maximum, minimum, scanl, sort,
    replicate, unfoldr, unfoldrN, take, takeEnd, drop, dropEnd, splitAt,
    takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, dropSpace, strip,
    span, spanEnd, break, breakEnd, breakSubstring, group, groupBy,
    inits, tails, split, splitWith, lines, words, unlines, unwords,
    isPrefixOf, isSuffixOf, isInfixOf, stripPrefix, stripSuffix, elem,
    notElem, find, filter, partition, index, indexMaybe, (!?), elemIndex,
    elemIndices, elemIndexEnd, findIndex, findIndices, count, zip,
    zipWith, unzip, readInt, readInteger, copy,
    fromStrict, toStrict, fromChunks, toChunks,
    putStr, putStrLn, getLine, getContents, interact, readFile, writeFile,
    appendFile, hPutStr, hPutStrLn, hPut, hGetLine, hGetContents, hGet, hGetSome, hGetNonBlocking
  ) where

import Prelude hiding (head, last, tail, init, null, length, map, reverse,
                       foldl, foldl1, foldr, foldr1, concat, concatMap, any,
                       all, maximum, minimum, scanl, replicate, take, drop,
                       splitAt, takeWhile, dropWhile, span, break, lines,
                       words, unlines, unwords, elem, notElem, filter, zip,
                       zipWith, unzip, putStr, putStrLn, getLine,
                       getContents, interact, readFile, writeFile,
                       appendFile)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.Char as C
import qualified System.IO as IO
import System.IO (Handle)
import Data.ByteString.Rep
import qualified Data.Text as T
import Data.Text.Rep (Text(..))
import TextPrims (primBytesReadFile, primBytesHGetContents, primBytesHPutStr)
import IOBase (Handle(..))

infixl 9 !?

pack :: String -> ByteString
pack = packChars

unpack :: ByteString -> String
unpack = unBS

-- a Text function on the bytes
on :: (Text -> Text) -> ByteString -> ByteString
on f (BS t) = BS (f t)

unT :: ByteString -> Text
unT (BS t) = t

bsList :: [Text] -> [ByteString]
bsList = P.map BS

empty :: ByteString
empty = BS T.empty

singleton :: Char -> ByteString
singleton c = BS (T.singleton c)

cons :: Char -> ByteString -> ByteString
cons c = on (T.cons c)

snoc :: ByteString -> Char -> ByteString
snoc b c = on (`T.snoc` c) b

append :: ByteString -> ByteString -> ByteString
append (BS a) (BS b) = BS (T.append a b)

emptyError :: String -> a
emptyError f = error ("Data.ByteString." ++ f ++ ": empty ByteString")

head, last :: ByteString -> Char
head b = if null b then emptyError "head" else T.head (unT b)
last b = if null b then emptyError "last" else T.last (unT b)

tail, init :: ByteString -> ByteString
tail b = if null b then emptyError "tail" else on T.tail b
init b = if null b then emptyError "init" else on T.init b

uncons :: ByteString -> Maybe (Char, ByteString)
uncons (BS t) = fmap (\(c, r) -> (c, BS r)) (T.uncons t)

unsnoc :: ByteString -> Maybe (ByteString, Char)
unsnoc (BS t) = fmap (\(r, c) -> (BS r, c)) (T.unsnoc t)

null :: ByteString -> Bool
null (BS t) = T.null t

length :: ByteString -> Int
length (BS t) = T.length t

map :: (Char -> Char) -> ByteString -> ByteString
map f = on (T.map f)

reverse :: ByteString -> ByteString
reverse = on T.reverse

intercalate :: ByteString -> [ByteString] -> ByteString
intercalate (BS sep) bs = BS (T.intercalate sep (P.map unT bs))

intersperse :: Char -> ByteString -> ByteString
intersperse c = on (T.intersperse c)

transpose :: [ByteString] -> [ByteString]
transpose bs = bsList (T.transpose (P.map unT bs))

foldl, foldl' :: (a -> Char -> a) -> a -> ByteString -> a
foldl f z (BS t) = T.foldl f z t
foldl' f z (BS t) = T.foldl' f z t

foldl1 :: (Char -> Char -> Char) -> ByteString -> Char
foldl1 f (BS t) = T.foldl1 f t

foldr, foldr' :: (Char -> a -> a) -> a -> ByteString -> a
foldr f z (BS t) = T.foldr f z t
foldr' f z b = L.foldl' (flip f) z (P.reverse (unpack b))

foldr1 :: (Char -> Char -> Char) -> ByteString -> Char
foldr1 f (BS t) = T.foldr1 f t

concat :: [ByteString] -> ByteString
concat bs = BS (T.concat (P.map unT bs))

concatMap :: (Char -> ByteString) -> ByteString -> ByteString
concatMap f (BS t) = BS (T.concatMap (unT . f) t)

any, all :: (Char -> Bool) -> ByteString -> Bool
any p (BS t) = T.any p t
all p (BS t) = T.all p t

maximum, minimum :: ByteString -> Char
maximum b = if null b then emptyError "maximum" else T.maximum (unT b)
minimum b = if null b then emptyError "minimum" else T.minimum (unT b)

scanl :: (Char -> Char -> Char) -> Char -> ByteString -> ByteString
scanl f z = on (T.scanl f z)

replicate :: Int -> Char -> ByteString
replicate n c = BS (T.replicate n (T.singleton c))

unfoldr :: (a -> Maybe (Char, a)) -> a -> ByteString
unfoldr f z = pack (L.unfoldr f z)

unfoldrN :: Int -> (a -> Maybe (Char, a)) -> a -> (ByteString, Maybe a)
unfoldrN n f z = go n z []
  where go 0 s acc = (pack (P.reverse acc), Just s)
        go k s acc = case f s of
                       Nothing -> (pack (P.reverse acc), Nothing)
                       Just (c, s') -> go (k - 1) s' (c : acc)

take, takeEnd, drop, dropEnd :: Int -> ByteString -> ByteString
take n = on (T.take n)
drop n = on (T.drop n)
takeEnd n = on (T.takeEnd n)
dropEnd n = on (T.dropEnd n)

splitAt :: Int -> ByteString -> (ByteString, ByteString)
splitAt n (BS t) = let (a, b) = T.splitAt n t in (BS a, BS b)

takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, filter
  :: (Char -> Bool) -> ByteString -> ByteString
takeWhile p = on (T.takeWhile p)
dropWhile p = on (T.dropWhile p)
takeWhileEnd p = on (T.takeWhileEnd p)
dropWhileEnd p = on (T.dropWhileEnd p)
filter p = on (T.filter p)

dropSpace, strip :: ByteString -> ByteString
dropSpace = on T.stripStart
strip = on T.strip

span, spanEnd, break, breakEnd
  :: (Char -> Bool) -> ByteString -> (ByteString, ByteString)
span p (BS t) = let (a, b) = T.span p t in (BS a, BS b)
break p (BS t) = let (a, b) = T.break p t in (BS a, BS b)
spanEnd p b = let n = T.length (T.takeWhileEnd p (unT b))
              in splitAt (length b - n) b
breakEnd p = spanEnd (not . p)

breakSubstring :: ByteString -> ByteString -> (ByteString, ByteString)
breakSubstring pat b
  | null pat = (empty, b)
  | otherwise = let (x, y) = T.breakOn (unT pat) (unT b) in (BS x, BS y)

group :: ByteString -> [ByteString]
group (BS t) = bsList (T.group t)

groupBy :: (Char -> Char -> Bool) -> ByteString -> [ByteString]
groupBy f (BS t) = bsList (T.groupBy f t)

inits, tails :: ByteString -> [ByteString]
inits (BS t) = bsList (T.inits t)
tails (BS t) = bsList (T.tails t)

split :: Char -> ByteString -> [ByteString]
split c b
  | null b = []
  | otherwise = bsList (T.splitOn (T.singleton c) (unT b))

splitWith :: (Char -> Bool) -> ByteString -> [ByteString]
splitWith p b
  | null b = []
  | otherwise = bsList (T.split p (unT b))

lines, words :: ByteString -> [ByteString]
lines (BS t) = bsList (T.lines t)
words (BS t) = bsList (T.words t)

unlines, unwords :: [ByteString] -> ByteString
unlines bs = BS (T.unlines (P.map unT bs))
unwords bs = BS (T.unwords (P.map unT bs))

isPrefixOf, isSuffixOf, isInfixOf :: ByteString -> ByteString -> Bool
isPrefixOf (BS a) (BS b) = T.isPrefixOf a b
isSuffixOf (BS a) (BS b) = T.isSuffixOf a b
isInfixOf (BS a) (BS b) = T.isInfixOf a b

stripPrefix, stripSuffix :: ByteString -> ByteString -> Maybe ByteString
stripPrefix (BS p) (BS s) = fmap BS (T.stripPrefix p s)
stripSuffix (BS p) (BS s) = fmap BS (T.stripSuffix p s)

elem, notElem :: Char -> ByteString -> Bool
elem c (BS t) = T.elem c t
notElem c b = not (elem c b)

find :: (Char -> Bool) -> ByteString -> Maybe Char
find p (BS t) = T.find p t

partition :: (Char -> Bool) -> ByteString -> (ByteString, ByteString)
partition p (BS t) = let (a, b) = T.partition p t in (BS a, BS b)

index :: ByteString -> Int -> Char
index b n
  | n < 0 || n >= length b = error ("Data.ByteString.index: index too large: " ++ show n)
  | otherwise = T.index (unT b) n

indexMaybe, (!?) :: ByteString -> Int -> Maybe Char
indexMaybe b n
  | n < 0 || n >= length b = Nothing
  | otherwise = Just (T.index (unT b) n)
(!?) = indexMaybe

elemIndex, elemIndexEnd :: Char -> ByteString -> Maybe Int
elemIndex c (BS t) = T.findIndex (== c) t
elemIndexEnd c b = case T.length (T.takeWhileEnd (/= c) (unT b)) of
                     n | n == length b -> Nothing
                       | otherwise -> Just (length b - n - 1)

elemIndices :: Char -> ByteString -> [Int]
elemIndices c = findIndices (== c)

findIndex :: (Char -> Bool) -> ByteString -> Maybe Int
findIndex p (BS t) = T.findIndex p t

findIndices :: (Char -> Bool) -> ByteString -> [Int]
findIndices p b = go 0 (unT b)
  where go off t = case T.findIndex p t of
                     Nothing -> []
                     Just i -> (off + i) : go (off + i + 1) (T.drop (i + 1) t)

count :: Char -> ByteString -> Int
count c (BS t) = T.count (T.singleton c) t

zip :: ByteString -> ByteString -> [(Char, Char)]
zip a b = P.zip (unpack a) (unpack b)

zipWith :: (Char -> Char -> a) -> ByteString -> ByteString -> [a]
zipWith f a b = P.zipWith f (unpack a) (unpack b)

unzip :: [(Char, Char)] -> (ByteString, ByteString)
unzip ps = let (a, b) = P.unzip ps in (pack a, pack b)

-- readInt "-42 rest" = Just (-42, " rest")
readInt :: ByteString -> Maybe (Int, ByteString)
readInt b = case readInteger b of
              Just (n, r) -> Just (fromInteger n, r)
              Nothing -> Nothing

readInteger :: ByteString -> Maybe (Integer, ByteString)
readInteger b = case uncons b of
    Just ('-', r) -> fmap (\(n, r') -> (negate n, r')) (digits r)
    Just ('+', r) -> digits r
    _ -> digits b
  where digits str = case span C.isDigit str of
          (ds, r) | null ds -> Nothing
                  | otherwise -> Just (foldl' (\a d -> a * 10 + toInteger (C.digitToInt d)) 0 ds, r)

copy :: ByteString -> ByteString
copy b = b

fromStrict, toStrict :: ByteString -> ByteString
fromStrict b = b
toStrict b = b

fromChunks :: [ByteString] -> ByteString
fromChunks = concat

toChunks :: ByteString -> [ByteString]
toChunks b = if null b then [] else [b]

-- I/O: bytes (binary mode)
putStr, putStrLn :: ByteString -> IO ()
putStr = hPutStr IO.stdout
putStrLn = hPutStrLn IO.stdout

getLine :: IO ByteString
getLine = hGetLine IO.stdin

getContents :: IO ByteString
getContents = do
  IO.hSetBinaryMode IO.stdin True
  hGetContents IO.stdin

interact :: (ByteString -> ByteString) -> IO ()
interact f = getContents >>= putStr . f

readFile :: FilePath -> IO ByteString
readFile f = primBytesReadFile f >>= return . BS . Text

writeFile, appendFile :: FilePath -> ByteString -> IO ()
writeFile f b = do
  h <- IO.openBinaryFile f IO.WriteMode
  hPutStr h b
  IO.hClose h
appendFile f b = do
  h <- IO.openBinaryFile f IO.AppendMode
  hPutStr h b
  IO.hClose h

hPutStr, hPutStrLn, hPut :: Handle -> ByteString -> IO ()
hPutStr (Handle h) (BS (Text s)) = primBytesHPutStr h s
hPutStrLn h b = hPutStr h (snoc b '\n')
hPut = hPutStr

hGetLine, hGetContents :: Handle -> IO ByteString
hGetLine h = fmap pack (IO.hGetLine h)
hGetContents (Handle h) = primBytesHGetContents h >>= return . BS . Text

-- | At most n bytes (here, as hGet, waiting for them).
hGetSome, hGetNonBlocking :: Handle -> Int -> IO ByteString
hGetSome = hGet
hGetNonBlocking = hGet

hGet :: Handle -> Int -> IO ByteString
hGet h n = fmap pack (go n)
  where go 0 = return []
        go k = do
          eof <- IO.hIsEOF h
          if eof then return [] else do
            c <- IO.hGetChar h
            cs <- go (k - 1)
            return (c : cs)

-- | The characters in order.
sort :: ByteString -> ByteString
sort = pack . L.sort . unpack

mapAccumL, mapAccumR :: (acc -> Char -> (acc, Char)) -> acc -> ByteString -> (acc, ByteString)
mapAccumL f acc b = case L.mapAccumL f acc (unpack b) of (a, xs) -> (a, pack xs)
mapAccumR f acc b = case L.mapAccumR f acc (unpack b) of (a, xs) -> (a, pack xs)
