-- Data.Char: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module Char
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module Data.Char (
    Char, String,
    isControl, isSpace, isLower, isUpper, isAlpha, isLetter, isDigit,
    isOctDigit, isHexDigit, isAlphaNum, isPrint, isPunctuation, isSymbol,
    isSeparator, isMark, isNumber, isAscii, isLatin1, isAsciiUpper, isAsciiLower,
    GeneralCategory(..), generalCategory,
    toUpper, toLower, toTitle, digitToInt, intToDigit, ord, chr,
    showLitChar, lexLitChar, readLitChar
  ) where

import Char
import CharPrims

-- Unicode general categories, in the Report's order.
data GeneralCategory
  = UppercaseLetter | LowercaseLetter | TitlecaseLetter | ModifierLetter
  | OtherLetter | NonSpacingMark | SpacingCombiningMark | EnclosingMark
  | DecimalNumber | LetterNumber | OtherNumber | ConnectorPunctuation
  | DashPunctuation | OpenPunctuation | ClosePunctuation | InitialQuote
  | FinalQuote | OtherPunctuation | MathSymbol | CurrencySymbol
  | ModifierSymbol | OtherSymbol | Space | LineSeparator | ParagraphSeparator
  | Control | Format | Surrogate | PrivateUse | NotAssigned
  deriving (Eq, Ord, Enum, Bounded, Ix, Show, Read)

generalCategory :: Char -> GeneralCategory
generalCategory c = toEnum (primGeneralCategory c)

isLetter :: Char -> Bool
isLetter c = generalCategory c <= OtherLetter

isMark :: Char -> Bool
isMark c = let g = generalCategory c in g >= NonSpacingMark && g <= EnclosingMark

isNumber :: Char -> Bool
isNumber c = let g = generalCategory c in g >= DecimalNumber && g <= OtherNumber

isPunctuation :: Char -> Bool
isPunctuation c = let g = generalCategory c in g >= ConnectorPunctuation && g <= OtherPunctuation

isSymbol :: Char -> Bool
isSymbol c = let g = generalCategory c in g >= MathSymbol && g <= OtherSymbol

isSeparator :: Char -> Bool
isSeparator c = let g = generalCategory c in g >= Space && g <= ParagraphSeparator

isAsciiUpper, isAsciiLower :: Char -> Bool
isAsciiUpper c = c >= 'A' && c <= 'Z'
isAsciiLower c = c >= 'a' && c <= 'z'

-- Title case: the upper case mapping (they differ only for a few
-- digraphs such as U+01C6).
toTitle :: Char -> Char
toTitle = toUpper
