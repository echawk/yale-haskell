-- Data.ByteString.Builder.Scientific (scientific): Scientific numbers as builders, formatted
-- as Data.Scientific's formatScientific and show.
module Data.ByteString.Builder.Scientific (scientificBuilder, formatScientificBuilder, FPFormat(..)) where

import qualified Data.ByteString.Builder as B
import Data.ByteString.Builder (Builder)
import Data.Scientific (Scientific, formatScientific)
import Data.Text.Lazy.Builder.RealFloat (FPFormat(..))

scientificBuilder :: Scientific -> Builder
scientificBuilder = B.string8 . show

formatScientificBuilder :: FPFormat -> Maybe Int -> Scientific -> Builder
formatScientificBuilder fmt decs = B.string8 . formatScientific fmt decs
