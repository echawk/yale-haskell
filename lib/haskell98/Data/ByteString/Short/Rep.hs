-- Data.ByteString.Short.Rep: Yale Haskell's ShortByteString, a
-- ByteString in a newtype (Data.ByteString.Short), with its instances.
module Data.ByteString.Short.Rep (ShortByteString(..)) where

import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.ByteString (ByteString)
import Data.String (IsString(..))
import Control.DeepSeq (NFData(..))

newtype ShortByteString = ShortByteString ByteString
  deriving (Eq, Ord)

instance Show ShortByteString where
  showsPrec p (ShortByteString b) = showsPrec p b

instance Read ShortByteString where
  readsPrec p s = [(ShortByteString b, r) | (b, r) <- readsPrec p s]

instance Semigroup ShortByteString where
  ShortByteString a <> ShortByteString b = ShortByteString (a <> b)

instance Monoid ShortByteString where
  mempty = ShortByteString mempty

instance IsString ShortByteString where
  fromString = ShortByteString . fromString

instance NFData ShortByteString where
  rnf (ShortByteString b) = rnf b
