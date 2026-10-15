-- Data.Text.Rep: Yale Haskell's Text type with its constructor, for the
-- modules of the text package here (Data.Text, Data.Text.IO).
module Data.Text.Rep (Text(..)) where

import TextPrims (TextRep)

newtype Text = Text TextRep
