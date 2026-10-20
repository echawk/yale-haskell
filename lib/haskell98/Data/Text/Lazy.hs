-- Data.Text.Lazy (text): its own type, as in text, so that a program may
-- give instances for both; underneath it is the strict, packed Text, and
-- each function is Data.Text's (a newtype is erased, so unsafeCoerce
-- changes only the type; Int64 is Integer, which Int's values are).
-- Generated once from Data.Text's signatures; keep the two in step.
module Data.Text.Lazy (
    Text, fromStrict, toStrict, fromChunks, toChunks, pack, unpack, empty, singleton, cons, snoc, append, uncons, unsnoc, head, last, tail, init, null, length, compareLength, map, intercalate, intersperse, transpose, reverse, replace, toCaseFold, toLower, toUpper, toTitle, justifyLeft, justifyRight, center, foldl, foldl', foldl1, foldr, foldr1, concat, concatMap, any, all, maximum, minimum, scanl, scanl1, scanr, scanr1, mapAccumL, mapAccumR, replicate, unfoldr, unfoldrN, take, takeEnd, drop, dropEnd, takeWhile, takeWhileEnd, dropWhile, dropWhileEnd, dropAround, strip, stripStart, stripEnd, splitAt, breakOn, breakOnEnd, break, span, spanM, group, groupBy, inits, tails, splitOn, split, chunksOf, lines, words, unlines, unwords, isPrefixOf, isSuffixOf, isInfixOf, stripPrefix, stripSuffix, commonPrefixes, filter, breakOnAll, find, elem, partition, index, findIndex, count, zip, zipWith, copy, unpackCString
  ) where

import Prelude ()
import qualified Prelude as P
import Prelude (Char, Bool, Int, Maybe, Ordering, String, Eq((==)), Ord(compare),
                Show(showsPrec), Read(readsPrec), Monad, (.), map)
import qualified Data.Text as S
import Data.Int (Int64)
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.String (IsString(fromString))
import Unsafe.Coerce (unsafeCoerce)
import Control.DeepSeq (NFData(rnf))

newtype Text = Text S.Text

instance Eq Text where
  Text a == Text b = a == b
instance Ord Text where
  compare (Text a) (Text b) = compare a b
instance Show Text where
  showsPrec p (Text t) = showsPrec p t
instance Read Text where
  readsPrec p s = [(Text t, r) | (t, r) <- readsPrec p s]
instance Semigroup Text where
  Text a <> Text b = Text (a <> b)
instance Monoid Text where
  mempty = Text mempty
instance IsString Text where
  fromString s = Text (fromString s)

fromStrict :: S.Text -> Text
fromStrict = Text

toStrict :: Text -> S.Text
toStrict (Text t) = t

fromChunks :: [S.Text] -> Text
fromChunks ts = Text (S.concat ts)

toChunks :: Text -> [S.Text]
toChunks (Text t) = if S.null t then [] else [t]

pack :: String -> Text
pack = unsafeCoerce S.pack

unpack :: Text -> String
unpack = unsafeCoerce S.unpack

empty :: Text
empty = unsafeCoerce S.empty

singleton :: Char -> Text
singleton = unsafeCoerce S.singleton

cons :: Char -> Text -> Text
cons = unsafeCoerce S.cons

snoc :: Text -> Char -> Text
snoc = unsafeCoerce S.snoc

append :: Text -> Text -> Text
append = unsafeCoerce S.append

uncons :: Text -> Maybe (Char, Text)
uncons = unsafeCoerce S.uncons

unsnoc :: Text -> Maybe (Text, Char)
unsnoc = unsafeCoerce S.unsnoc

head :: Text -> Char
head = unsafeCoerce S.head

last :: Text -> Char
last = unsafeCoerce S.last

tail :: Text -> Text
tail = unsafeCoerce S.tail

init :: Text -> Text
init = unsafeCoerce S.init

null :: Text -> Bool
null = unsafeCoerce S.null

length :: Text -> Int64
length = unsafeCoerce S.length

compareLength :: Text -> Int64 -> Ordering
compareLength = unsafeCoerce S.compareLength

map :: (Char -> Char) -> Text -> Text
map = unsafeCoerce S.map

intercalate :: Text -> [Text] -> Text
intercalate = unsafeCoerce S.intercalate

intersperse :: Char -> Text -> Text
intersperse = unsafeCoerce S.intersperse

transpose :: [Text] -> [Text]
transpose = unsafeCoerce S.transpose

reverse :: Text -> Text
reverse = unsafeCoerce S.reverse

replace :: Text -> Text -> Text -> Text
replace = unsafeCoerce S.replace

toCaseFold :: Text -> Text
toCaseFold = unsafeCoerce S.toCaseFold

toLower :: Text -> Text
toLower = unsafeCoerce S.toLower

toUpper :: Text -> Text
toUpper = unsafeCoerce S.toUpper

toTitle :: Text -> Text
toTitle = unsafeCoerce S.toTitle

justifyLeft :: Int -> Char -> Text -> Text
justifyLeft = unsafeCoerce S.justifyLeft

justifyRight :: Int -> Char -> Text -> Text
justifyRight = unsafeCoerce S.justifyRight

center :: Int -> Char -> Text -> Text
center = unsafeCoerce S.center

foldl :: (a -> Char -> a) -> a -> Text -> a
foldl = unsafeCoerce S.foldl

foldl' :: (a -> Char -> a) -> a -> Text -> a
foldl' = unsafeCoerce S.foldl'

foldl1 :: (Char -> Char -> Char) -> Text -> Char
foldl1 = unsafeCoerce S.foldl1

foldr :: (Char -> a -> a) -> a -> Text -> a
foldr = unsafeCoerce S.foldr

foldr1 :: (Char -> Char -> Char) -> Text -> Char
foldr1 = unsafeCoerce S.foldr1

concat :: [Text] -> Text
concat = unsafeCoerce S.concat

concatMap :: (Char -> Text) -> Text -> Text
concatMap = unsafeCoerce S.concatMap

any :: (Char -> Bool) -> Text -> Bool
any = unsafeCoerce S.any

all :: (Char -> Bool) -> Text -> Bool
all = unsafeCoerce S.all

maximum :: Text -> Char
maximum = unsafeCoerce S.maximum

minimum :: Text -> Char
minimum = unsafeCoerce S.minimum

scanl :: (Char -> Char -> Char) -> Char -> Text -> Text
scanl = unsafeCoerce S.scanl

scanl1 :: (Char -> Char -> Char) -> Text -> Text
scanl1 = unsafeCoerce S.scanl1

scanr :: (Char -> Char -> Char) -> Char -> Text -> Text
scanr = unsafeCoerce S.scanr

scanr1 :: (Char -> Char -> Char) -> Text -> Text
scanr1 = unsafeCoerce S.scanr1

mapAccumL :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumL = unsafeCoerce S.mapAccumL

mapAccumR :: (a -> Char -> (a, Char)) -> a -> Text -> (a, Text)
mapAccumR = unsafeCoerce S.mapAccumR

replicate :: Int64 -> Text -> Text
replicate = unsafeCoerce S.replicate

unfoldr :: (a -> Maybe (Char, a)) -> a -> Text
unfoldr = unsafeCoerce S.unfoldr

unfoldrN :: Int64 -> (a -> Maybe (Char, a)) -> a -> Text
unfoldrN = unsafeCoerce S.unfoldrN

take :: Int64 -> Text -> Text
take = unsafeCoerce S.take

takeEnd :: Int64 -> Text -> Text
takeEnd = unsafeCoerce S.takeEnd

drop :: Int64 -> Text -> Text
drop = unsafeCoerce S.drop

dropEnd :: Int64 -> Text -> Text
dropEnd = unsafeCoerce S.dropEnd

strip :: Text -> Text
strip = unsafeCoerce S.strip

stripStart :: Text -> Text
stripStart = unsafeCoerce S.stripStart

stripEnd :: Text -> Text
stripEnd = unsafeCoerce S.stripEnd

splitAt :: Int64 -> Text -> (Text, Text)
splitAt = unsafeCoerce S.splitAt

breakOn :: Text -> Text -> (Text, Text)
breakOn = unsafeCoerce S.breakOn

breakOnEnd :: Text -> Text -> (Text, Text)
breakOnEnd = unsafeCoerce S.breakOnEnd

break :: (Char -> Bool) -> Text -> (Text, Text)
break = unsafeCoerce S.break

span :: (Char -> Bool) -> Text -> (Text, Text)
span = unsafeCoerce S.span

spanM :: Monad m => (Char -> m Bool) -> Text -> m (Text, Text)
spanM p (Text t) = S.spanM p t P.>>= \(a, b) -> P.return (Text a, Text b)

group :: Text -> [Text]
group = unsafeCoerce S.group

groupBy :: (Char -> Char -> Bool) -> Text -> [Text]
groupBy = unsafeCoerce S.groupBy

inits :: Text -> [Text]
inits = unsafeCoerce S.inits

tails :: Text -> [Text]
tails = unsafeCoerce S.tails

splitOn :: Text -> Text -> [Text]
splitOn = unsafeCoerce S.splitOn

split :: (Char -> Bool) -> Text -> [Text]
split = unsafeCoerce S.split

chunksOf :: Int64 -> Text -> [Text]
chunksOf = unsafeCoerce S.chunksOf

lines :: Text -> [Text]
lines = unsafeCoerce S.lines

words :: Text -> [Text]
words = unsafeCoerce S.words

unlines :: [Text] -> Text
unlines = unsafeCoerce S.unlines

unwords :: [Text] -> Text
unwords = unsafeCoerce S.unwords

isPrefixOf :: Text -> Text -> Bool
isPrefixOf = unsafeCoerce S.isPrefixOf

isSuffixOf :: Text -> Text -> Bool
isSuffixOf = unsafeCoerce S.isSuffixOf

isInfixOf :: Text -> Text -> Bool
isInfixOf = unsafeCoerce S.isInfixOf

stripPrefix :: Text -> Text -> Maybe Text
stripPrefix = unsafeCoerce S.stripPrefix

stripSuffix :: Text -> Text -> Maybe Text
stripSuffix = unsafeCoerce S.stripSuffix

commonPrefixes :: Text -> Text -> Maybe (Text, Text, Text)
commonPrefixes = unsafeCoerce S.commonPrefixes

breakOnAll :: Text -> Text -> [(Text, Text)]
breakOnAll = unsafeCoerce S.breakOnAll

find :: (Char -> Bool) -> Text -> Maybe Char
find = unsafeCoerce S.find

elem :: Char -> Text -> Bool
elem = unsafeCoerce S.elem

partition :: (Char -> Bool) -> Text -> (Text, Text)
partition = unsafeCoerce S.partition

index :: Text -> Int64 -> Char
index = unsafeCoerce S.index

findIndex :: (Char -> Bool) -> Text -> Maybe Int
findIndex = unsafeCoerce S.findIndex

count :: Text -> Text -> Int64
count = unsafeCoerce S.count

zip :: Text -> Text -> [(Char, Char)]
zip = unsafeCoerce S.zip

zipWith :: (Char -> Char -> Char) -> Text -> Text -> Text
zipWith = unsafeCoerce S.zipWith

copy :: Text -> Text
copy = unsafeCoerce S.copy

unpackCString :: String -> Text
unpackCString = unsafeCoerce S.unpackCString

takeWhile :: (Char -> Bool) -> Text -> Text
takeWhile = unsafeCoerce S.takeWhile

takeWhileEnd :: (Char -> Bool) -> Text -> Text
takeWhileEnd = unsafeCoerce S.takeWhileEnd

dropWhile :: (Char -> Bool) -> Text -> Text
dropWhile = unsafeCoerce S.dropWhile

dropWhileEnd :: (Char -> Bool) -> Text -> Text
dropWhileEnd = unsafeCoerce S.dropWhileEnd

dropAround :: (Char -> Bool) -> Text -> Text
dropAround = unsafeCoerce S.dropAround

filter :: (Char -> Bool) -> Text -> Text
filter = unsafeCoerce S.filter

instance NFData Text where
  rnf (Text t) = rnf t
