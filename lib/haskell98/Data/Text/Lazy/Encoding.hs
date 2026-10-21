-- Data.Text.Lazy.Encoding (text): lazy Text and lazy ByteStrings.
module Data.Text.Lazy.Encoding (
    encodeUtf8, encodeUtf8Builder, encodeUtf8BuilderEscaped, decodeUtf8, decodeUtf8', decodeUtf8With, decodeLatin1
  ) where

import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString.Lazy.Internal as LI
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Encoding as E
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Builder.Prim as BP
import Data.Word (Word8)
import Data.Text.Encoding.Error (UnicodeException, OnDecodeError)

encodeUtf8 :: TL.Text -> L.ByteString
encodeUtf8 t = LI.LBS (E.encodeUtf8 (TL.toStrict t))

decodeUtf8 :: L.ByteString -> TL.Text
decodeUtf8 (LI.LBS b) = TL.fromStrict (E.decodeUtf8 b)

decodeUtf8' :: L.ByteString -> Either UnicodeException TL.Text
decodeUtf8' (LI.LBS b) = fmap TL.fromStrict (E.decodeUtf8' b)

decodeUtf8With :: OnDecodeError -> L.ByteString -> TL.Text
decodeUtf8With h (LI.LBS b) = TL.fromStrict (E.decodeUtf8With h b)

decodeLatin1 :: L.ByteString -> TL.Text
decodeLatin1 (LI.LBS b) = TL.fromStrict (E.decodeLatin1 b)

encodeUtf8Builder :: TL.Text -> BB.Builder
encodeUtf8Builder = E.encodeUtf8Builder . TL.toStrict

encodeUtf8BuilderEscaped :: BP.BoundedPrim Word8 -> TL.Text -> BB.Builder
encodeUtf8BuilderEscaped p = E.encodeUtf8BuilderEscaped p . TL.toStrict
