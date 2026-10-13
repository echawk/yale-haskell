-- Data.Text.Lazy (text): the same type as a strict Text here, as
-- Data.ByteString.Lazy is the strict ByteString (Data.Text); fromStrict
-- and toStrict are the identity.
module Data.Text.Lazy (module Data.Text, fromStrict, toStrict, fromChunks, toChunks) where

import Prelude ()
import qualified Prelude as P
import Data.Text

fromStrict, toStrict :: Text -> Text
fromStrict t = t
toStrict t = t

fromChunks :: [Text] -> Text
fromChunks = concat

toChunks :: Text -> [Text]
toChunks t = if null t then [] else [t]
