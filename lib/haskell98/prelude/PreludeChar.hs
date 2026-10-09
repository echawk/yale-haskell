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
maxChar			= '\1114111'

ord			:: Char -> Int
ord 			=  primCharToInt

chr 			:: Int -> Char
chr 			=  primIntToChar

isAscii, isLatin1, isControl, isPrint, isSpace, isUpper, isLower,
  isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum :: Char -> Bool

isAscii c	=  c < '\128'

isLatin1 c	=  c <= '\255'

isControl c	=  c < ' ' || (c >= '\DEL' && c <= '\159')

-- Char is Unicode (report 6.1.2): letters, case and printability follow
-- the Unicode character properties (the host's tables); isAlpha is
-- any letter, as in GHC.  isSpace, isDigit, isControl and the
-- hexadecimal and octal tests are the Report's.
isPrint c	=  primUnicodeIsPrint c

isSpace c	=  c == ' '  || c == '\t' || c == '\n' ||
		   c == '\r' || c == '\f' || c == '\v' || c == '\160'

isUpper c	=  primUnicodeIsUpper c

isLower c	=  primUnicodeIsLower c

isAlpha c	=  primUnicodeIsAlpha c

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

-- Unicode simple case mapping.
toUpper, toLower	:: Char -> Char
toUpper c		=  primUnicodeToUpper c
toLower c		=  primUnicodeToLower c