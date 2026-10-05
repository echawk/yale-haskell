-- The Haskell 98 Numeric library.
--
-- The definitions are in the Prelude's internal module PreludeNumeric
-- (the Report's libraries/code/Numeric.hs; see the notice there),
-- because the Prelude's Text instances use them.

module Numeric(fromRat,
               showSigned, showIntAtBase,
               showInt, showOct, showHex,
               readSigned, readInt,
               readDec, readOct, readHex,
               floatToDigits,
               showEFloat, showFFloat, showGFloat, showFloat,
               readFloat, lexDigits) where

import PreludeNumeric
