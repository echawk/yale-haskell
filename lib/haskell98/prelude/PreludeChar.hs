-- Character functions (the Haskell 98 Char library, minus the
-- readLitChar/showLitChar/lexLitChar group, which is in PreludeText).
--
-- Adapted from the Haskell 98 Report, libraries/code/Char.hs:
--   The authors intend this Report to belong to the entire Haskell
--   community, and so we grant permission to copy and distribute it for
--   any purpose, provided that it is reproduced in its entirety,
--   including this Notice.  Modified versions of this Report may also be
--   copied and distributed for any purpose, provided that the modified
--   version is clearly presented as such, and that it does not claim to
--   be a definition of the language Haskell 98.
-- Modified for Yale Haskell: characters are Latin-1 (codes 0-255), so the
-- Unicode primitives are replaced by Latin-1 tests.

module PreludeChar (
    isAscii, isLatin1, isControl, isPrint, isSpace, isUpper, isLower,
    isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum,
    digitToInt, intToDigit, toUpper, toLower, ord, chr,
    minChar, maxChar ) where

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

import PreludePrims

minChar, maxChar	:: Char
minChar			= '\0'
maxChar			= '\255'

ord			:: Char -> Int
ord 			=  primCharToInt

chr 			:: Int -> Char
chr 			=  primIntToChar

isAscii, isLatin1, isControl, isPrint, isSpace, isUpper, isLower,
  isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum :: Char -> Bool

isAscii c	=  c < '\128'

isLatin1 c	=  c <= '\255'

isControl c	=  c < ' ' || (c >= '\DEL' && c <= '\159')

isPrint c	=  (c >= ' ' && c <= '~') || (c >= '\160' && c /= '\173')

isSpace c	=  c == ' '  || c == '\t' || c == '\n' ||
		   c == '\r' || c == '\f' || c == '\v' || c == '\160'

isUpper c	=  (c >= 'A' && c <= 'Z') ||
		   (c >= '\192' && c <= '\222' && c /= '\215')

isLower c	=  (c >= 'a' && c <= 'z') || c == '\181' ||
		   (c >= '\223' && c /= '\247')

isAlpha c	=  isUpper c || isLower c

isDigit c	=  c >= '0' && c <= '9'

isOctDigit c	=  c >= '0' && c <= '7'

isHexDigit c	=  isDigit c || (c >= 'A' && c <= 'F') ||
				(c >= 'a' && c <= 'f')

isAlphaNum c	=  isAlpha c || isDigit c

digitToInt :: Char -> Int
digitToInt c
  | isDigit c		 =  ord c - ord '0'
  | c >= 'a' && c <= 'f' =  ord c - ord 'a' + 10
  | c >= 'A' && c <= 'F' =  ord c - ord 'A' + 10
  | otherwise		 =  error "Char.digitToInt: not a digit"

intToDigit :: Int -> Char
intToDigit i
  | i >= 0  && i <=  9	 =  chr (ord '0' + i)
  | i >= 10 && i <= 15	 =  chr (ord 'a' + i - 10)
  | otherwise		 =  error "Char.intToDigit: not a digit"

-- Latin-1 case mapping: the upper and lower ranges differ by 32,
-- except for the multiplication and division signs; sharp s, micro
-- and y-diaeresis have no Latin-1 counterpart.
toUpper, toLower	:: Char -> Char
toUpper c
  | c >= 'a' && c <= 'z'			= chr (ord c - 32)
  | c >= '\224' && c <= '\254' && c /= '\247'	= chr (ord c - 32)
  | otherwise					= c

toLower c
  | c >= 'A' && c <= 'Z'			= chr (ord c + 32)
  | c >= '\192' && c <= '\222' && c /= '\215'	= chr (ord c + 32)
  | otherwise					= c
