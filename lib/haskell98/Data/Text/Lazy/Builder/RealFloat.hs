-- Data.Text.Lazy.Builder.RealFloat (text): floating-point numbers as
-- Builders, through Numeric's show functions.
module Data.Text.Lazy.Builder.RealFloat (FPFormat(..), realFloat, formatRealFloat) where

import Data.Text.Lazy.Builder (Builder, fromString)
import Numeric (showEFloat, showFFloat)

data FPFormat = Exponent | Fixed | Generic
  deriving (Enum, Read, Show)

realFloat :: RealFloat a => a -> Builder
realFloat x = formatRealFloat Generic Nothing x

formatRealFloat :: RealFloat a => FPFormat -> Maybe Int -> a -> Builder
formatRealFloat fmt decs x = fromString (case fmt of
  Fixed -> showFFloat decs x ""
  Exponent -> showEFloat decs x ""
  Generic -> let a = abs x in
             if a /= 0 && (a < 0.1 || a >= 10000000) then showEFloat decs x ""
             else showFFloat decs x "")
