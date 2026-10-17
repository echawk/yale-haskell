-- Data.ByteString.Short (bytestring): ShortByteString.  Yale Haskell's
-- ByteString is already one packed string (Data.ByteString), so a
-- ShortByteString is a ByteString and the conversions are free.
module Data.ByteString.Short (
    ShortByteString, toShort, fromShort, pack, unpack, empty, null, length,
    index, indexMaybe, (!?), append, concat
  ) where

import Prelude hiding (null, length, concat)
import Data.ByteString (ByteString, pack, unpack, empty, null, length, index,
                        indexMaybe, (!?), append, concat)

type ShortByteString = ByteString

toShort :: ByteString -> ShortByteString
toShort b = b

fromShort :: ShortByteString -> ByteString
fromShort b = b
