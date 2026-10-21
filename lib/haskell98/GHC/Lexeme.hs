-- GHC.Lexeme (ghc-boot-th): what character starts which kind of name.
module GHC.Lexeme (
    startsVarSym, startsVarSymASCII, isVarSymChar, startsConSym,
    startsVarId, startsConId
  ) where

import Data.Char (isSymbol, isUpper, generalCategory, GeneralCategory(..))

startsVarSym, startsVarSymASCII, isVarSymChar, startsConSym,
  startsVarId, startsConId :: Char -> Bool
startsVarSym c = startsVarSymASCII c || (fromEnum c > 0x7f && isSymbol c)
startsVarSymASCII c = c `elem` "!#$%&*+./<=>?@\\^|~-"
isVarSymChar c = c == ':' || startsVarSym c
startsConSym c = c == ':'
startsVarId c = c == '_' || case generalCategory c of
  LowercaseLetter -> True
  OtherLetter -> True
  _ -> False
startsConId c = isUpper c || c == '('
