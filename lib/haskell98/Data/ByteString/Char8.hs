-- Data.ByteString.Char8 (bytestring): ByteStrings as Chars (Latin-1).
module Data.ByteString.Char8 (
    ByteString, pack, unpack, empty, singleton, cons, snoc, append, head,
    last, tail, init, uncons, unsnoc, null, length, map, reverse,
    intercalate, intersperse, transpose, foldl, foldl', foldl1, foldr,
    foldr', foldr1, concat, concatMap, any, all, maximum, minimum, scanl,
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
    appendFile, hPutStr, hPutStrLn, hPut, hGetLine, hGetContents, hGet
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
import Data.ByteString.Internal

infixl 9 !?

pack :: String -> ByteString
pack = packChars

unpack :: ByteString -> String
unpack (BS s) = s

lift :: (String -> String) -> ByteString -> ByteString
lift f (BS s) = BS (f s)

empty :: ByteString
empty = BS ""

singleton :: Char -> ByteString
singleton c = BS [c]

cons :: Char -> ByteString -> ByteString
cons c (BS s) = BS (c : s)

snoc :: ByteString -> Char -> ByteString
snoc (BS s) c = BS (s ++ [c])

append :: ByteString -> ByteString -> ByteString
append (BS a) (BS b) = BS (a ++ b)

emptyError :: String -> a
emptyError f = error ("Data.ByteString." ++ f ++ ": empty ByteString")

head, last :: ByteString -> Char
head (BS s) = if P.null s then emptyError "head" else P.head s
last (BS s) = if P.null s then emptyError "last" else P.last s

tail, init :: ByteString -> ByteString
tail (BS s) = if P.null s then emptyError "tail" else BS (P.tail s)
init (BS s) = if P.null s then emptyError "init" else BS (P.init s)

uncons :: ByteString -> Maybe (Char, ByteString)
uncons (BS (c : s)) = Just (c, BS s)
uncons _ = Nothing

unsnoc :: ByteString -> Maybe (ByteString, Char)
unsnoc (BS []) = Nothing
unsnoc (BS s) = Just (BS (P.init s), P.last s)

null :: ByteString -> Bool
null (BS s) = P.null s

length :: ByteString -> Int
length (BS s) = P.length s

map :: (Char -> Char) -> ByteString -> ByteString
map f = lift (P.map f)

reverse :: ByteString -> ByteString
reverse = lift P.reverse

intercalate :: ByteString -> [ByteString] -> ByteString
intercalate (BS sep) bs = BS (L.intercalate sep (P.map unpack bs))

intersperse :: Char -> ByteString -> ByteString
intersperse c = lift (L.intersperse c)

transpose :: [ByteString] -> [ByteString]
transpose bs = P.map BS (L.transpose (P.map unpack bs))

foldl, foldl' :: (a -> Char -> a) -> a -> ByteString -> a
foldl f z (BS s) = P.foldl f z s
foldl' f z (BS s) = L.foldl' f z s

foldl1 :: (Char -> Char -> Char) -> ByteString -> Char
foldl1 f (BS s) = P.foldl1 f s

foldr, foldr' :: (Char -> a -> a) -> a -> ByteString -> a
foldr f z (BS s) = P.foldr f z s
foldr' f z (BS s) = L.foldl' (flip f) z (P.reverse s)

foldr1 :: (Char -> Char -> Char) -> ByteString -> Char
foldr1 f (BS s) = P.foldr1 f s

concat :: [ByteString] -> ByteString
concat bs = BS (P.concatMap unpack bs)

concatMap :: (Char -> ByteString) -> ByteString -> ByteString
concatMap f (BS s) = BS (P.concatMap (unpack . f) s)

any, all :: (Char -> Bool) -> ByteString -> Bool
any p (BS s) = P.any p s
all p (BS s) = P.all p s

maximum, minimum :: ByteString -> Char
maximum (BS s) = P.maximum s
minimum (BS s) = P.minimum s

scanl :: (Char -> Char -> Char) -> Char -> ByteString -> ByteString
scanl f z = lift (P.scanl f z)

replicate :: Int -> Char -> ByteString
replicate n c = BS (P.replicate n c)

unfoldr :: (a -> Maybe (Char, a)) -> a -> ByteString
unfoldr f z = BS (L.unfoldr f z)

unfoldrN :: Int -> (a -> Maybe (Char, a)) -> a -> (ByteString, Maybe a)
unfoldrN n f z = go n z []
  where go 0 s acc = (BS (P.reverse acc), Just s)
        go k s acc = case f s of
                       Nothing -> (BS (P.reverse acc), Nothing)
                       Just (c, s') -> go (k - 1) s' (c : acc)

take, takeEnd, drop, dropEnd :: Int -> ByteString -> ByteString
take n (BS s) = BS (P.take n s)
drop n (BS s) = BS (P.drop n s)
takeEnd n (BS s) = BS (P.drop (P.length s - n) s)
dropEnd n (BS s) = BS (P.take (P.length s - n) s)

splitAt :: Int -> ByteString -> (ByteString, ByteString)
splitAt n (BS s) = let (a, b) = P.splitAt n s in (BS a, BS b)

takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, filter
  :: (Char -> Bool) -> ByteString -> ByteString
takeWhile p (BS s) = BS (P.takeWhile p s)
dropWhile p (BS s) = BS (P.dropWhile p s)
takeWhileEnd p (BS s) = BS (P.reverse (P.takeWhile p (P.reverse s)))
dropWhileEnd p (BS s) = BS (L.dropWhileEnd p s)
filter p (BS s) = BS (P.filter p s)

dropSpace, strip :: ByteString -> ByteString
dropSpace = dropWhile C.isSpace
strip = dropWhile C.isSpace . dropWhileEnd C.isSpace

span, spanEnd, break, breakEnd
  :: (Char -> Bool) -> ByteString -> (ByteString, ByteString)
span p (BS s) = let (a, b) = P.span p s in (BS a, BS b)
break p (BS s) = let (a, b) = P.break p s in (BS a, BS b)
spanEnd p (BS s) = let (b, a) = P.span p (P.reverse s)
                   in (BS (P.reverse a), BS (P.reverse b))
breakEnd p = spanEnd (not . p)

breakSubstring :: ByteString -> ByteString -> (ByteString, ByteString)
breakSubstring (BS pat) (BS s) = let (a, b) = go s in (BS a, BS b)
  where go [] = ([], [])
        go str@(c : cs)
          | pat `L.isPrefixOf` str = ([], str)
          | otherwise = let (a, b) = go cs in (c : a, b)

group :: ByteString -> [ByteString]
group (BS s) = P.map BS (L.group s)

groupBy :: (Char -> Char -> Bool) -> ByteString -> [ByteString]
groupBy f (BS s) = P.map BS (L.groupBy f s)

inits, tails :: ByteString -> [ByteString]
inits (BS s) = P.map BS (L.inits s)
tails (BS s) = P.map BS (L.tails s)

split :: Char -> ByteString -> [ByteString]
split c = splitWith (== c)

splitWith :: (Char -> Bool) -> ByteString -> [ByteString]
splitWith p (BS s)
  | P.null s = []
  | otherwise = P.map BS (go s)
  where go str = case P.break p str of
                   (a, []) -> [a]
                   (a, _ : rest) -> a : go rest

lines, words :: ByteString -> [ByteString]
lines (BS s) = P.map BS (P.lines s)
words (BS s) = P.map BS (P.words s)

unlines, unwords :: [ByteString] -> ByteString
unlines bs = BS (P.unlines (P.map unpack bs))
unwords bs = BS (P.unwords (P.map unpack bs))

isPrefixOf, isSuffixOf, isInfixOf :: ByteString -> ByteString -> Bool
isPrefixOf (BS a) (BS b) = L.isPrefixOf a b
isSuffixOf (BS a) (BS b) = L.isSuffixOf a b
isInfixOf (BS a) (BS b) = L.isInfixOf a b

stripPrefix, stripSuffix :: ByteString -> ByteString -> Maybe ByteString
stripPrefix (BS p) (BS s) = fmap BS (L.stripPrefix p s)
stripSuffix (BS p) (BS s) =
  fmap (BS . P.reverse) (L.stripPrefix (P.reverse p) (P.reverse s))

elem, notElem :: Char -> ByteString -> Bool
elem c (BS s) = P.elem c s
notElem c (BS s) = P.notElem c s

find :: (Char -> Bool) -> ByteString -> Maybe Char
find p (BS s) = L.find p s

partition :: (Char -> Bool) -> ByteString -> (ByteString, ByteString)
partition p (BS s) = let (a, b) = L.partition p s in (BS a, BS b)

index :: ByteString -> Int -> Char
index (BS s) n = s !! n

indexMaybe, (!?) :: ByteString -> Int -> Maybe Char
indexMaybe (BS s) n
  | n < 0 = Nothing
  | otherwise = case P.drop n s of { (c : _) -> Just c; [] -> Nothing }
(!?) = indexMaybe

elemIndex, elemIndexEnd :: Char -> ByteString -> Maybe Int
elemIndex c (BS s) = L.elemIndex c s
elemIndexEnd c (BS s) = case L.elemIndices c s of
                          [] -> Nothing
                          is -> Just (P.last is)

elemIndices :: Char -> ByteString -> [Int]
elemIndices c (BS s) = L.elemIndices c s

findIndex :: (Char -> Bool) -> ByteString -> Maybe Int
findIndex p (BS s) = L.findIndex p s

findIndices :: (Char -> Bool) -> ByteString -> [Int]
findIndices p (BS s) = L.findIndices p s

count :: Char -> ByteString -> Int
count c (BS s) = P.length (P.filter (== c) s)

zip :: ByteString -> ByteString -> [(Char, Char)]
zip (BS a) (BS b) = P.zip a b

zipWith :: (Char -> Char -> a) -> ByteString -> ByteString -> [a]
zipWith f (BS a) (BS b) = P.zipWith f a b

unzip :: [(Char, Char)] -> (ByteString, ByteString)
unzip ps = let (a, b) = P.unzip ps in (BS a, BS b)

-- readInt "-42 rest" = Just (-42, " rest")
readInt :: ByteString -> Maybe (Int, ByteString)
readInt b = case readInteger b of
              Just (n, r) -> Just (fromInteger n, r)
              Nothing -> Nothing

readInteger :: ByteString -> Maybe (Integer, ByteString)
readInteger (BS s) = case s of
    ('-' : r) -> fmap (\(n, r') -> (negate n, r')) (digits r)
    ('+' : r) -> digits r
    _ -> digits s
  where digits str = case P.span C.isDigit str of
          ([], _) -> Nothing
          (ds, r) -> Just (L.foldl' (\a d -> a * 10 + toInteger (C.digitToInt d)) 0 ds, BS r)

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
putStr (BS s) = P.putStr s
putStrLn (BS s) = P.putStrLn s

getLine :: IO ByteString
getLine = fmap BS P.getLine

getContents :: IO ByteString
getContents = do
  IO.hSetBinaryMode IO.stdin True
  fmap BS P.getContents

interact :: (ByteString -> ByteString) -> IO ()
interact f = getContents >>= putStr . f

readFile :: FilePath -> IO ByteString
readFile f = do
  h <- IO.openBinaryFile f IO.ReadMode
  s <- IO.hGetContents h
  P.length s `seq` IO.hClose h
  return (BS s)

writeFile, appendFile :: FilePath -> ByteString -> IO ()
writeFile f (BS s) = do
  h <- IO.openBinaryFile f IO.WriteMode
  IO.hPutStr h s
  IO.hClose h
appendFile f (BS s) = do
  h <- IO.openBinaryFile f IO.AppendMode
  IO.hPutStr h s
  IO.hClose h

hPutStr, hPutStrLn, hPut :: Handle -> ByteString -> IO ()
hPutStr h (BS s) = IO.hPutStr h s
hPutStrLn h (BS s) = IO.hPutStrLn h s
hPut = hPutStr

hGetLine, hGetContents :: Handle -> IO ByteString
hGetLine h = fmap BS (IO.hGetLine h)
hGetContents h = fmap BS (IO.hGetContents h)

hGet :: Handle -> Int -> IO ByteString
hGet h n = fmap BS (go n)
  where go 0 = return []
        go k = do
          eof <- IO.hIsEOF h
          if eof then return [] else do
            c <- IO.hGetChar h
            cs <- go (k - 1)
            return (c : cs)
