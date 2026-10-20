-- Data.ByteString.Lazy.Internal (bytestring): the lazy ByteString, its
-- own type as in bytestring, over the strict one (Yale Haskell reads a
-- file in one piece either way).  Data.ByteString.Lazy and
-- Data.ByteString.Lazy.Char8 are generated over it
-- (tools/gen/lazy-bytestring.py).
module Data.ByteString.Lazy.Internal (ByteString(LBS)) where

import qualified Data.ByteString.Rep as S
import PreludeModern (Semigroup((<>)), Monoid(mempty))
import Data.String (IsString(fromString))
import Control.DeepSeq (NFData(rnf))

newtype ByteString = LBS S.ByteString

instance Eq ByteString where
  LBS a == LBS b = a == b
instance Ord ByteString where
  compare (LBS a) (LBS b) = compare a b
instance Show ByteString where
  showsPrec p (LBS b) = showsPrec p b
instance Read ByteString where
  readsPrec p s = [(LBS b, r) | (b, r) <- readsPrec p s]
instance Semigroup ByteString where
  LBS a <> LBS b = LBS (a <> b)
instance Monoid ByteString where
  mempty = LBS mempty
instance IsString ByteString where
  fromString s = LBS (fromString s)

instance NFData ByteString where
  rnf (LBS b) = rnf b
