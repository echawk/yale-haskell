-- Data.Text (text): a Text is a packed string, a Lisp string
-- (TextPrims.hi, src/base/text-runtime.lisp).  The common operations
-- are primitives; the rest go through String.  Not here: the
-- .Internal/.Unsafe/.Array modules (text's own representation).
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
                       unwords, filter, elem, zip, zipWith, index)
import qualified Prelude as P
import qualified Data.List as L
import qualified Data.Char as C
import PreludeModern (Semigroup((<>)), Monoid(mempty, mappend))
import Data.String (IsString(fromString))
import TextPrims
import Data.Text.Rep (Text(..))
import Unsafe.Coerce (unsafeCoerce)

instance Eq Text where
  Text a == Text b = primTextEq a b
instance Ord Text where
  compare (Text a) (Text b) = case primTextCompare a b of
                                0 -> EQ
                                n -> if n < 0 then LT else GT
instance Show Text where
  showsPrec p t = showsPrec p (unpack t)
instance Read Text where
  readsPrec p s = [(pack x, r) | (x, r) <- readsPrec p s]
instance Semigroup Text where
  (<>) = append
instance Monoid Text where
  mempty = empty
instance IsString Text where
  fromString = pack

toList :: [Text] -> TextList
toList = unsafeCoerce

fromList :: TextList -> [Text]
fromList = unsafeCoerce

pack :: String -> Text
pack s = Text (primTextPack s)

unpack :: Text -> String
unpack (Text s) = primTextUnpack s

unpackCString :: String -> Text
unpackCString = pack

lift :: (String -> String) -> Text -> Text
lift f t = pack (f (unpack t))

empty :: Text
empty = pack ""

singleton :: Char -> Text
singleton c = Text (primTextSingleton c)

cons :: Char -> Text -> Text
cons c (Text s) = Text (primTextCons c s)

snoc :: Text -> Char -> Text
snoc (Text s) c = Text (primTextSnoc s c)

append :: Text -> Text -> Text
append (Text a) (Text b) = Text (primTextAppend a b)

slice :: Text -> Int -> Int -> Text
slice (Text s) a b = Text (primTextSlice s a b)

uncons :: Text -> Maybe (Char, Text)
uncons t | null t = Nothing
         | otherwise = Just (unsafeHead t, slice t 1 (length t))

unsnoc :: Text -> Maybe (Text, Char)
unsnoc t | null t = Nothing
         | otherwise = let n = length t in Just (slice t 0 (n - 1), index t (n - 1))

emptyError :: String -> a
emptyError f = error ("Data.Text." ++ f ++ ": empty input")

unsafeHead :: Text -> Char
unsafeHead (Text s) = primTextIndex s 0

head :: Text -> Char
head t = if null t then emptyError "head" else unsafeHead t

last :: Text -> Char
last t = if null t then emptyError "last" else index t (length t - 1)

tail :: Text -> Text
tail t = if null t then emptyError "tail" else slice t 1 (length t)

init :: Text -> Text
init t = if null t then emptyError "init" else slice t 0 (length t - 1)

null :: Text -> Bool
null t = length t == 0

length :: Text -> Int
length (Text s) = primTextLength s

compareLength :: Text -> Int -> Ordering
compareLength t n = compare (length t) n

map :: (Char -> Char) -> Text -> Text
map f (Text s) = Text (primTextMap f s)

intercalate :: Text -> [Text] -> Text
intercalate (Text sep) ts = Text (primTextIntercalate sep (toList ts))

intersperse :: Char -> Text -> Text
intersperse c = lift (L.intersperse c)

transpose :: [Text] -> [Text]
transpose ts = P.map pack (L.transpose (P.map unpack ts))

reverse :: Text -> Text
reverse (Text s) = Text (primTextReverse s)

-- replace needle replacement haystack
replace :: Text -> Text -> Text -> Text
replace (Text needle) (Text rep) (Text hay)
  | primTextLength needle == 0 = error "Data.Text.replace: empty input"
  | otherwise = Text (primTextReplace needle rep hay)

toCaseFold, toLower, toUpper, toTitle :: Text -> Text
toCaseFold = toLower
toLower (Text s) = Text (primTextToLower s)
toUpper (Text s) = Text (primTextToUpper s)
toTitle t = pack (go True (unpack t))
  where go _ [] = []
        go up (c : cs)
          | C.isAlpha c = (if up then C.toUpper c else C.toLower c) : go False cs
          | otherwise = c : go True cs

justifyLeft, justifyRight, center :: Int -> Char -> Text -> Text
justifyLeft k c t = append t (replicateChar (k - length t) c)
justifyRight k c t = append (replicateChar (k - length t) c) t
center k c t =
  let len = length t
      d = k - len
      r = d `div` 2
      l = d - r
  in if len >= k then t
     else concat [replicateChar l c, t, replicateChar r c]

replicateChar :: Int -> Char -> Text
replicateChar n c = replicate n (singleton c)

foldl :: (a -> Char -> a) -> a -> Text -> a
foldl f z t = P.foldl f z (unpack t)

foldl' :: (a -> Char -> a) -> a -> Text -> a
foldl' f z (Text s) = primTextFoldlStrict f z s

foldl1 :: (Char -> Char -> Char) -> Text -> Char
foldl1 f t = if null t then emptyError "foldl1" else foldl' f (unsafeHead t) (tail t)

foldr :: (Char -> a -> a) -> a -> Text -> a
foldr f z t = P.foldr f z (unpack t)

foldr1 :: (Char -> Char -> Char) -> Text -> Char
foldr1 f t = P.foldr1 f (unpack t)

concat :: [Text] -> Text
concat ts = Text (primTextConcat (toList ts))

concatMap :: (Char -> Text) -> Text -> Text
concatMap f t = concat (P.map f (unpack t))

any, all :: (Char -> Bool) -> Text -> Bool
any p t = findIndexInt p t >= 0
all p t = findIndexInt (not . p) t < 0

maximum, minimum :: Text -> Char
maximum t = if null t then emptyError "maximum" else foldl1 max t
minimum t = if null t then emptyError "minimum" else foldl1 min t

scanl :: (Char -> Char -> Char) -> Char -> Text -> Text
scanl f z = lift (P.scanl f z)

scanl1 :: (Char -> Char -> Char) -> Text -> Text
scanl1 f = lift (P.scanl1 f)

scanr :: (Char -> Char -> Char) -> Char -> Text -> Text
scanr f z = lift (P.scanr f z)

scanr1 :: (Char -> Char -> Char) -> Text -> Text
scanr1 f = lift (P.scanr1 f)

mapAccumL :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumL f z t = let (a, s') = L.mapAccumL f z (unpack t) in (a, pack s')

mapAccumR :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumR f z t = let (a, s') = L.mapAccumR f z (unpack t) in (a, pack s')

replicate :: Int -> Text -> Text
replicate n (Text s) = Text (primTextReplicate n s)

unfoldr :: (a -> Maybe (Char, a)) -> a -> Text
unfoldr f z = pack (L.unfoldr f z)

unfoldrN :: Int -> (a -> Maybe (Char, a)) -> a -> Text
unfoldrN n f z = pack (P.take n (L.unfoldr f z))

take, takeEnd, drop, dropEnd :: Int -> Text -> Text
take n t = slice t 0 n
drop n t = slice t n (length t)
takeEnd n t = let l = length t in slice t (l - max 0 n) l
dropEnd n t = slice t 0 (length t - max 0 n)

takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, dropAround,
  filter :: (Char -> Bool) -> Text -> Text
takeWhile p t@(Text s) = slice t 0 (primTextSpanLength p s)
dropWhile p t@(Text s) = slice t (primTextSpanLength p s) (length t)
takeWhileEnd p t@(Text s) = let l = length t in slice t (l - primTextSpanLengthEnd p s) l
dropWhileEnd p t@(Text s) = slice t 0 (length t - primTextSpanLengthEnd p s)
dropAround p = dropWhile p . dropWhileEnd p
filter p (Text s) = Text (primTextFilter p s)

strip, stripStart, stripEnd :: Text -> Text
strip (Text s) = Text (primTextStrip s 0)
stripStart (Text s) = Text (primTextStrip s 1)
stripEnd (Text s) = Text (primTextStrip s 2)

splitAt :: Int -> Text -> (Text, Text)
splitAt n t = (take n t, drop n t)

search :: Text -> Text -> Int -> Int
search (Text needle) (Text hay) i = primTextSearch needle hay i

-- breakOn needle haystack: the text before the first needle, and the rest
breakOn :: Text -> Text -> (Text, Text)
breakOn needle hay
  | null needle = error "Data.Text.breakOn: empty input"
  | otherwise = case search needle hay 0 of
                  -1 -> (hay, empty)
                  i -> (take i hay, drop i hay)

breakOnEnd :: Text -> Text -> (Text, Text)
breakOnEnd needle hay =
  let (a, b) = breakOn (reverse needle) (reverse hay)
  in if null b then (empty, hay)
     else (reverse (drop (length needle) b) `append` needle, reverse a)

breakOnAll :: Text -> Text -> [(Text, Text)]
breakOnAll needle hay
  | null needle = error "Data.Text.breakOnAll: empty input"
  | otherwise = go 0
  where go i = case search needle hay i of
                 -1 -> []
                 j -> (take j hay, drop j hay) : go (j + 1)

break, span :: (Char -> Bool) -> Text -> (Text, Text)
break p = span (not . p)
span p t@(Text s) = splitAt (primTextSpanLength p s) t

spanM :: Monad m => (Char -> m Bool) -> Text -> m (Text, Text)
spanM p t = go 0
  where n = length t
        go i | i >= n = return (t, empty)
             | otherwise = do
                 ok <- p (index t i)
                 if ok then go (i + 1) else return (splitAt i t)

group :: Text -> [Text]
group = groupBy (==)

groupBy :: (Char -> Char -> Bool) -> Text -> [Text]
groupBy f t = P.map pack (L.groupBy f (unpack t))

inits, tails :: Text -> [Text]
inits t = [take i t | i <- [0 .. length t]]
tails t = [drop i t | i <- [0 .. length t]]

-- splitOn separator text
splitOn :: Text -> Text -> [Text]
splitOn (Text sep) (Text s)
  | primTextLength sep == 0 = error "Data.Text.splitOn: empty delimiter"
  | otherwise = fromList (primTextSplitOn sep s)

split :: (Char -> Bool) -> Text -> [Text]
split p t = case findIndexInt p t of
              -1 -> [t]
              i -> take i t : split p (drop (i + 1) t)

chunksOf :: Int -> Text -> [Text]
chunksOf k t
  | k <= 0 = []
  | null t = []
  | otherwise = take k t : chunksOf k (drop k t)

lines, words :: Text -> [Text]
lines (Text s) = fromList (primTextLines s)
words (Text s) = fromList (primTextWords s)

unlines, unwords :: [Text] -> Text
unlines ts = Text (primTextUnlines (toList ts))
unwords ts = Text (primTextUnwords (toList ts))

isPrefixOf, isSuffixOf, isInfixOf :: Text -> Text -> Bool
isPrefixOf (Text a) (Text b) = primTextIsPrefix a b
isSuffixOf (Text a) (Text b) = primTextIsSuffix a b
isInfixOf (Text a) (Text b) = primTextIsInfix a b

stripPrefix, stripSuffix :: Text -> Text -> Maybe Text
stripPrefix p t
  | p `isPrefixOf` t = Just (drop (length p) t)
  | otherwise = Nothing
stripSuffix p t
  | p `isSuffixOf` t = Just (dropEnd (length p) t)
  | otherwise = Nothing

commonPrefixes :: Text -> Text -> Maybe (Text, Text, Text)
commonPrefixes a b =
  let n = P.length (P.takeWhile id (P.zipWith (==) (unpack a) (unpack b)))
  in if n == 0 then Nothing
     else Just (take n a, drop n a, drop n b)

findIndexInt :: (Char -> Bool) -> Text -> Int
findIndexInt p (Text s) = primTextFindIndex p s

find :: (Char -> Bool) -> Text -> Maybe Char
find p t = case findIndexInt p t of
             -1 -> Nothing
             i -> Just (index t i)

elem :: Char -> Text -> Bool
elem c t = findIndexInt (== c) t >= 0

partition :: (Char -> Bool) -> Text -> (Text, Text)
partition p t = (filter p t, filter (not . p) t)

index :: Text -> Int -> Char
index t@(Text s) n
  | n < 0 || n >= length t = error "Data.Text.index: index out of bounds"
  | otherwise = primTextIndex s n

findIndex :: (Char -> Bool) -> Text -> Maybe Int
findIndex p t = case findIndexInt p t of
                  -1 -> Nothing
                  i -> Just i

-- count needle haystack: non-overlapping occurrences
count :: Text -> Text -> Int
count (Text needle) (Text hay)
  | primTextLength needle == 0 = error "Data.Text.count: empty input"
  | otherwise = primTextCount needle hay

zip :: Text -> Text -> [(Char, Char)]
zip a b = P.zip (unpack a) (unpack b)

zipWith :: (Char -> Char -> Char) -> Text -> Text -> Text
zipWith f a b = pack (P.zipWith f (unpack a) (unpack b))

copy :: Text -> Text
copy t = t
