-- Data.Text.Lazy.Builder (text): a Builder is the list of strict chunks
-- it appends (a difference list), concatenated once by toLazyText.
module Data.Text.Lazy.Builder (
    Builder, toLazyText, toLazyTextWith, singleton, fromText,
    fromLazyText, fromString, flush
  ) where

import qualified Data.Text as S
import qualified Data.Text.Lazy as L
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import qualified Data.String as DS

newtype Builder = Builder ([S.Text] -> [S.Text])

instance Semigroup Builder where
  Builder f <> Builder g = Builder (f . g)
instance Monoid Builder where
  mempty = Builder id
instance DS.IsString Builder where
  fromString = fromString
instance Show Builder where
  showsPrec p b = showsPrec p (toLazyText b)
instance Eq Builder where
  a == b = toLazyText a == toLazyText b
instance Ord Builder where
  compare a b = compare (toLazyText a) (toLazyText b)

toLazyText :: Builder -> L.Text
toLazyText (Builder f) = L.fromStrict (S.concat (f []))

toLazyTextWith :: Int -> Builder -> L.Text
toLazyTextWith _ = toLazyText

singleton :: Char -> Builder
singleton c = fromText (S.singleton c)

fromText :: S.Text -> Builder
fromText t = Builder (t :)

fromLazyText :: L.Text -> Builder
fromLazyText t = fromText (L.toStrict t)

fromString :: String -> Builder
fromString s = fromText (S.pack s)

flush :: Builder
flush = mempty
