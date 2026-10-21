{-# LANGUAGE OverloadedStrings #-}
import Data.ByteString.Builder (Builder, toLazyByteString, word8)
import qualified Data.ByteString.Lazy as L
newtype E = E { fromE :: Builder }
main = print (L.unpack (toLazyByteString (fromE (E "h\233") <> word8 33)))
