-- Data.Text.Lazy.Builder.Scientific (scientific): Scientific numbers as builders, formatted
-- as Data.Scientific's formatScientific and show.
module Data.Text.Lazy.Builder.Scientific (scientificBuilder, formatScientificBuilder, FPFormat(..)) where

import qualified Data.Text.Lazy.Builder as B
import Data.Text.Lazy.Builder (Builder)
import Data.Scientific (Scientific, formatScientific)
import Data.Text.Lazy.Builder.RealFloat (FPFormat(..))

scientificBuilder :: Scientific -> Builder
scientificBuilder = B.fromString . show

formatScientificBuilder :: FPFormat -> Maybe Int -> Scientific -> Builder
formatScientificBuilder fmt decs = B.fromString . formatScientific fmt decs
