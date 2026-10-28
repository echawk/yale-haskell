-- GHC.IO.Encoding.Failure (base): what a text encoding does with what it
-- cannot code.  Yale Haskell's encodings take no mode: the names only.
module GHC.IO.Encoding.Failure (CodingFailureMode(..), codingFailureModeSuffix) where

data CodingFailureMode
  = ErrorOnCodingFailure
  | IgnoreCodingFailure
  | TransliterateCodingFailure
  | RoundtripFailure
  deriving (Eq, Show)

codingFailureModeSuffix :: CodingFailureMode -> String
codingFailureModeSuffix ErrorOnCodingFailure = ""
codingFailureModeSuffix IgnoreCodingFailure = "//IGNORE"
codingFailureModeSuffix TransliterateCodingFailure = "//TRANSLIT"
codingFailureModeSuffix RoundtripFailure = "//ROUNDTRIP"
