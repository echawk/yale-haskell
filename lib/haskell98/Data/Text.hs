-- Data.Text (text): the API over a String.  Strict text is a fully
-- evaluated String here (pack forces it); the functions are the list
-- ones, so a program using Data.Text runs the same, without text's
-- packed representation.
module Data.Text (
    Text, pack, unpack, empty, singleton, cons, snoc, append, uncons,
    unsnoc, head, last, tail, init, null, length, compareLength, map,
    intercalate, intersperse, transpose, reverse, replace, toCaseFold,
    toLower, toUpper, toTitle, justifyLeft, justifyRight, center, foldl,
    foldl', foldl1, foldr, foldr1, concat, concatMap, any, all, maximum,
    minimum, scanl, scanl1, scanr, scanr1, mapAccumL, mapAccumR,
    replicate, unfoldr, unfoldrN, take, takeEnd, drop, dropEnd, takeWhile,
    takeWhileEnd, dropWhile, dropWhileEnd, dropAround, strip, stripStart,
    stripEnd, splitAt, breakOn, breakOnEnd, break, span, spanM, group,
    groupBy, inits, tails, splitOn, split, chunksOf, lines, words,
    unlines, unwords, isPrefixOf, isSuffixOf, isInfixOf, stripPrefix,
    stripSuffix, commonPrefixes, filter, breakOnAll, find, elem,
    partition, index, findIndex, count, zip, zipWith, copy, unpackCString
  ) where

import Prelude hiding (head, last, tail, init, null, length, map, reverse,
                       foldl, foldl1, foldr, foldr1, concat, concatMap, any,
                       all, maximum, minimum, scanl, scanl1, scanr, scanr1,
                       replicate, take, drop, takeWhile, dropWhile,
                       splitAt, break, span, lines, words, unlines,
                       unwords, filter, elem, zip, zipWith)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.Char as C
import PreludeModern (Semigroup((<>)), Monoid(mempty, mappend))
import Data.String (IsString(fromString))

newtype Text = Text String

instance Eq Text where
  Text a == Text b = a == b
instance Ord Text where
  compare (Text a) (Text b) = compare a b
instance Show Text where
  showsPrec p (Text s) = showsPrec p s
instance Read Text where
  readsPrec p s = [(Text x, r) | (x, r) <- readsPrec p s]
instance Semigroup Text where
  Text a <> Text b = Text (a ++ b)
instance Monoid Text where
  mempty = Text ""
instance IsString Text where
  fromString = pack

-- strict: the characters are evaluated
pack :: String -> Text
pack s = forceAll s `seq` Text s
  where forceAll = P.foldr seq ()

unpack :: Text -> String
unpack (Text s) = s

unpackCString :: String -> Text
unpackCString = pack

lift :: (String -> String) -> Text -> Text
lift f (Text s) = pack (f s)

empty :: Text
empty = Text ""

singleton :: Char -> Text
singleton c = Text [c]

cons :: Char -> Text -> Text
cons c (Text s) = Text (c : s)

snoc :: Text -> Char -> Text
snoc (Text s) c = Text (s ++ [c])

append :: Text -> Text -> Text
append (Text a) (Text b) = Text (a ++ b)

uncons :: Text -> Maybe (Char, Text)
uncons (Text (c : s)) = Just (c, Text s)
uncons _ = Nothing

unsnoc :: Text -> Maybe (Text, Char)
unsnoc (Text []) = Nothing
unsnoc (Text s) = Just (Text (P.init s), P.last s)

emptyError :: String -> a
emptyError f = error ("Data.Text." ++ f ++ ": empty input")

head :: Text -> Char
head (Text s) = if P.null s then emptyError "head" else P.head s

last :: Text -> Char
last (Text s) = if P.null s then emptyError "last" else P.last s

tail :: Text -> Text
tail (Text s) = if P.null s then emptyError "tail" else Text (P.tail s)

init :: Text -> Text
init (Text s) = if P.null s then emptyError "init" else Text (P.init s)

null :: Text -> Bool
null (Text s) = P.null s

length :: Text -> Int
length (Text s) = P.length s

compareLength :: Text -> Int -> Ordering
compareLength (Text s) n = compare (P.length s) n

map :: (Char -> Char) -> Text -> Text
map f = lift (P.map f)

intercalate :: Text -> [Text] -> Text
intercalate (Text sep) ts = pack (L.intercalate sep (P.map unpack ts))

intersperse :: Char -> Text -> Text
intersperse c = lift (L.intersperse c)

transpose :: [Text] -> [Text]
transpose ts = P.map pack (L.transpose (P.map unpack ts))

reverse :: Text -> Text
reverse = lift P.reverse

-- replace needle replacement haystack
replace :: Text -> Text -> Text -> Text
replace (Text needle) (Text rep) (Text hay)
  | P.null needle = error "Data.Text.replace: empty input"
  | otherwise = pack (go hay)
  where
    n = P.length needle
    go [] = []
    go s@(c : cs)
      | needle `L.isPrefixOf` s = rep ++ go (P.drop n s)
      | otherwise = c : go cs

toCaseFold, toLower, toUpper, toTitle :: Text -> Text
toCaseFold = toLower
toLower = map C.toLower
toUpper = map C.toUpper
toTitle (Text s) = pack (go True s)
  where go _ [] = []
        go up (c : cs)
          | C.isAlpha c = (if up then C.toUpper c else C.toLower c) : go False cs
          | otherwise = c : go True cs

justifyLeft, justifyRight, center :: Int -> Char -> Text -> Text
justifyLeft k c (Text s) = pack (s ++ P.replicate (k - P.length s) c)
justifyRight k c (Text s) = pack (P.replicate (k - P.length s) c ++ s)
center k c (Text s) =
  let len = P.length s
      d = k - len
      r = d `div` 2
      l = d - r
  in if len >= k then Text s
     else pack (P.replicate l c ++ s ++ P.replicate r c)

foldl :: (a -> Char -> a) -> a -> Text -> a
foldl f z (Text s) = P.foldl f z s

foldl' :: (a -> Char -> a) -> a -> Text -> a
foldl' f z (Text s) = L.foldl' f z s

foldl1 :: (Char -> Char -> Char) -> Text -> Char
foldl1 f (Text s) = P.foldl1 f s

foldr :: (Char -> a -> a) -> a -> Text -> a
foldr f z (Text s) = P.foldr f z s

foldr1 :: (Char -> Char -> Char) -> Text -> Char
foldr1 f (Text s) = P.foldr1 f s

concat :: [Text] -> Text
concat ts = Text (P.concatMap unpack ts)

concatMap :: (Char -> Text) -> Text -> Text
concatMap f (Text s) = Text (P.concatMap (unpack . f) s)

any, all :: (Char -> Bool) -> Text -> Bool
any p (Text s) = P.any p s
all p (Text s) = P.all p s

maximum, minimum :: Text -> Char
maximum (Text s) = P.maximum s
minimum (Text s) = P.minimum s

scanl :: (Char -> Char -> Char) -> Char -> Text -> Text
scanl f z = lift (P.scanl f z)

scanl1 :: (Char -> Char -> Char) -> Text -> Text
scanl1 f = lift (P.scanl1 f)

scanr :: (Char -> Char -> Char) -> Char -> Text -> Text
scanr f z = lift (P.scanr f z)

scanr1 :: (Char -> Char -> Char) -> Text -> Text
scanr1 f = lift (P.scanr1 f)

mapAccumL :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumL f z (Text s) = let (a, s') = L.mapAccumL f z s in (a, pack s')

mapAccumR :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumR f z (Text s) = let (a, s') = L.mapAccumR f z s in (a, pack s')

replicate :: Int -> Text -> Text
replicate n (Text s) = Text (P.concat (P.replicate n s))

unfoldr :: (a -> Maybe (Char, a)) -> a -> Text
unfoldr f z = pack (L.unfoldr f z)

unfoldrN :: Int -> (a -> Maybe (Char, a)) -> a -> Text
unfoldrN n f z = pack (P.take n (L.unfoldr f z))

take, takeEnd, drop, dropEnd :: Int -> Text -> Text
take n (Text s) = Text (P.take n s)
drop n (Text s) = Text (P.drop n s)
takeEnd n (Text s) = Text (P.drop (P.length s - n) s)
dropEnd n (Text s) = Text (P.take (P.length s - n) s)

takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, dropAround,
  filter :: (Char -> Bool) -> Text -> Text
takeWhile p (Text s) = Text (P.takeWhile p s)
dropWhile p (Text s) = Text (P.dropWhile p s)
takeWhileEnd p (Text s) = Text (P.reverse (P.takeWhile p (P.reverse s)))
dropWhileEnd p (Text s) = Text (L.dropWhileEnd p s)
dropAround p = dropWhile p . dropWhileEnd p
filter p (Text s) = Text (P.filter p s)

strip, stripStart, stripEnd :: Text -> Text
strip = dropAround C.isSpace
stripStart = dropWhile C.isSpace
stripEnd = dropWhileEnd C.isSpace

splitAt :: Int -> Text -> (Text, Text)
splitAt n (Text s) = let (a, b) = P.splitAt n s in (Text a, Text b)

-- breakOn needle haystack: the text before the first needle, and the rest
breakOn :: Text -> Text -> (Text, Text)
breakOn (Text needle) (Text hay)
  | P.null needle = error "Data.Text.breakOn: empty input"
  | otherwise = let (a, b) = go hay in (Text a, Text b)
  where
    go [] = ([], [])
    go s@(c : cs)
      | needle `L.isPrefixOf` s = ([], s)
      | otherwise = let (a, b) = go cs in (c : a, b)

breakOnEnd :: Text -> Text -> (Text, Text)
breakOnEnd needle hay =
  let (a, b) = breakOn (reverse needle) (reverse hay)
  in if null b then (empty, hay)
     else (reverse (drop (length needle) b) `append` needle, reverse a)

breakOnAll :: Text -> Text -> [(Text, Text)]
breakOnAll (Text needle) (Text hay) =
  [ (Text (P.take i hay), Text (P.drop i hay))
  | i <- [0 .. P.length hay - 1], needle `L.isPrefixOf` P.drop i hay ]

break, span :: (Char -> Bool) -> Text -> (Text, Text)
break p (Text s) = let (a, b) = P.break p s in (Text a, Text b)
span p (Text s) = let (a, b) = P.span p s in (Text a, Text b)

spanM :: Monad m => (Char -> m Bool) -> Text -> m (Text, Text)
spanM p (Text s) = go [] s
  where go acc [] = return (Text (P.reverse acc), Text [])
        go acc (c : cs) = do
          ok <- p c
          if ok then go (c : acc) cs else return (Text (P.reverse acc), Text (c : cs))

group :: Text -> [Text]
group (Text s) = P.map Text (L.group s)

groupBy :: (Char -> Char -> Bool) -> Text -> [Text]
groupBy f (Text s) = P.map Text (L.groupBy f s)

inits, tails :: Text -> [Text]
inits (Text s) = P.map Text (L.inits s)
tails (Text s) = P.map Text (L.tails s)

-- splitOn separator text
splitOn :: Text -> Text -> [Text]
splitOn (Text sep) (Text s)
  | P.null sep = error "Data.Text.splitOn: empty delimiter"
  | otherwise = P.map Text (go s)
  where
    n = P.length sep
    go str = case search str of
               (a, Nothing) -> [a]
               (a, Just rest) -> a : go rest
    search [] = ([], Nothing)
    search str@(c : cs)
      | sep `L.isPrefixOf` str = ([], Just (P.drop n str))
      | otherwise = let (a, r) = search cs in (c : a, r)

split :: (Char -> Bool) -> Text -> [Text]
split p (Text s) = P.map Text (go s)
  where go str = case P.break p str of
                   (a, []) -> [a]
                   (a, _ : rest) -> a : go rest

chunksOf :: Int -> Text -> [Text]
chunksOf k (Text s)
  | k <= 0 = []
  | otherwise = go s
  where go [] = []
        go str = Text (P.take k str) : go (P.drop k str)

lines, words :: Text -> [Text]
lines (Text s) = P.map Text (P.lines s)
words (Text s) = P.map Text (P.words s)

unlines, unwords :: [Text] -> Text
unlines ts = Text (P.unlines (P.map unpack ts))
unwords ts = Text (P.unwords (P.map unpack ts))

isPrefixOf, isSuffixOf, isInfixOf :: Text -> Text -> Bool
isPrefixOf (Text a) (Text b) = L.isPrefixOf a b
isSuffixOf (Text a) (Text b) = L.isSuffixOf a b
isInfixOf (Text a) (Text b) = L.isInfixOf a b

stripPrefix, stripSuffix :: Text -> Text -> Maybe Text
stripPrefix (Text p) (Text s) = fmap Text (L.stripPrefix p s)
stripSuffix (Text p) (Text s) =
  fmap (Text . P.reverse) (L.stripPrefix (P.reverse p) (P.reverse s))

commonPrefixes :: Text -> Text -> Maybe (Text, Text, Text)
commonPrefixes (Text a) (Text b) =
  let pre = P.map fst (P.takeWhile (uncurry (==)) (P.zip a b))
      n = P.length pre
  in if n == 0 then Nothing
     else Just (Text pre, Text (P.drop n a), Text (P.drop n b))

find :: (Char -> Bool) -> Text -> Maybe Char
find p (Text s) = L.find p s

elem :: Char -> Text -> Bool
elem c (Text s) = P.elem c s

partition :: (Char -> Bool) -> Text -> (Text, Text)
partition p (Text s) = let (a, b) = L.partition p s in (Text a, Text b)

index :: Text -> Int -> Char
index (Text s) n = s !! n

findIndex :: (Char -> Bool) -> Text -> Maybe Int
findIndex p (Text s) = L.findIndex p s

-- count needle haystack: non-overlapping occurrences
count :: Text -> Text -> Int
count (Text needle) (Text hay)
  | P.null needle = error "Data.Text.count: empty input"
  | otherwise = go hay
  where n = P.length needle
        go [] = 0
        go s@(_ : cs)
          | needle `L.isPrefixOf` s = 1 + go (P.drop n s)
          | otherwise = go cs

zip :: Text -> Text -> [(Char, Char)]
zip (Text a) (Text b) = P.zip a b

zipWith :: (Char -> Char -> Char) -> Text -> Text -> Text
zipWith f (Text a) (Text b) = pack (P.zipWith f a b)

copy :: Text -> Text
copy t = t
