-- The Haskell 98 Ratio library.
--
-- The definitions are in the Prelude's internal module PreludeRatio
-- (from the Report's libraries/code/Ratio.hs), because Rational is a
-- Prelude type.  (Yale Haskell requires a synonym to be exported as
-- Rational(..).)

module Ratio (
    Ratio, Rational(..), (%), numerator, denominator, approxRational ) where

import PreludeRatio(Ratio, Rational(..), (%), numerator, denominator,
		    approxRational)
