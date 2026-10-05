-- The Haskell 98 Complex library.
--
-- The definitions are in the Prelude's internal module PreludeComplex
-- (the Report's libraries/code/Complex.hs), because the compiler knows
-- the Complex type.

module Complex(Complex((:+)), realPart, imagPart, conjugate, mkPolar,
               cis, polar, magnitude, phase)  where

import PreludeComplex
