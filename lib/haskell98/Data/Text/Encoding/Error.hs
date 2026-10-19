-- Data.Text.Encoding.Error (text): what a decoder does with invalid input.
module Data.Text.Encoding.Error (
    UnicodeException(DecodeError, EncodeError), OnError, OnDecodeError,
    OnEncodeError, lenientDecode, strictDecode, ignore, replace
  ) where

import Control.Exception (Exception, throw)
import Data.Word (Word8)

data UnicodeException = DecodeError String (Maybe Word8)
                      | EncodeError String (Maybe Char)
  deriving (Eq)

instance Show UnicodeException where
  showsPrec _ (DecodeError desc (Just w)) =
    showString ("Cannot decode byte '\\x" ++ hex w ++ "': " ++ desc)
  showsPrec _ (DecodeError desc Nothing) = showString ("Cannot decode input: " ++ desc)
  showsPrec _ (EncodeError desc (Just c)) =
    showString ("Cannot encode character '" ++ [c] ++ "': " ++ desc)
  showsPrec _ (EncodeError desc Nothing) = showString ("Cannot encode input: " ++ desc)

hex :: Word8 -> String
hex w = [digits !! fromIntegral (w `div` 16), digits !! fromIntegral (w `mod` 16)]
  where digits = "0123456789abcdef"

instance Exception UnicodeException

type OnError a b = String -> Maybe a -> Maybe b
type OnDecodeError = OnError Word8 Char
type OnEncodeError = OnError Char Word8

lenientDecode :: OnDecodeError
lenientDecode _ _ = Just '\xfffd'

strictDecode :: OnDecodeError
strictDecode desc c = throw (DecodeError desc c)

ignore :: OnError a b
ignore _ _ = Nothing

replace :: b -> OnError a b
replace c _ _ = Just c
