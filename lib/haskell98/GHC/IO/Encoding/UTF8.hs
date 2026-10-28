-- GHC.IO.Encoding.UTF8 (base): UTF-8, System.IO's utf8 (Yale Haskell's
-- encodings take no failure mode).
module GHC.IO.Encoding.UTF8 (utf8, mkUTF8, utf8_bom, mkUTF8_bom) where

import System.IO (TextEncoding, utf8, utf8_bom)
import GHC.IO.Encoding.Failure (CodingFailureMode)

mkUTF8 :: CodingFailureMode -> TextEncoding
mkUTF8 _ = utf8

mkUTF8_bom :: CodingFailureMode -> TextEncoding
mkUTF8_bom _ = utf8_bom
