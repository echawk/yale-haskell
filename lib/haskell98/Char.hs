-- The Haskell 98 Char library.
--
-- The definitions are in the Prelude's internal modules PreludeChar and
-- PreludeText (adapted from the Report's libraries/code/Char.hs; see the
-- notice there); this module only collects them.  Characters are
-- Latin-1.

module Char (
    isAscii, isLatin1, isControl, isPrint, isSpace, isUpper, isLower,
    isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum,
    digitToInt, intToDigit,
    toUpper, toLower,
    ord, chr,
    readLitChar, showLitChar, lexLitChar

    -- ...and what the Prelude exports: Char, String
    ) where

import PreludeChar
import PreludeText(readLitChar, showLitChar, lexLitChar)
