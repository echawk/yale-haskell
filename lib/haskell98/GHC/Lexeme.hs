-- GHC.Lexeme (ghc-boot-th 9.14.1): the lexical classes of Haskell names,
-- from ghc-internal 9.1401.0's GHC/Internal/Lexeme.hs, unchanged but for
-- this header and the imports.  (c) The GHC Team; BSD licence,
-- Language/Haskell/LICENSE.template-haskell.
module GHC.Lexeme (
        startsVarSym, startsVarId, startsConSym, startsConId,
        startsVarSymASCII, isVarSymChar, okSymChar
  ) where

import Data.Char

okSymChar :: Char -> Bool
okSymChar c
  | c `elem` "(),;[]`{}_\"'"
  = False
  | otherwise
  = case generalCategory c of
      ConnectorPunctuation -> True
      DashPunctuation      -> True
      OtherPunctuation     -> True
      MathSymbol           -> True
      CurrencySymbol       -> True
      ModifierSymbol       -> True
      OtherSymbol          -> True
      _                    -> False

startsVarSym, startsVarId, startsConSym, startsConId :: Char -> Bool
startsVarSym c = okSymChar c && c /= ':' -- Infix Ids
startsConSym c = c == ':'                -- Infix data constructors
startsVarId c  = c == '_' || case generalCategory c of  -- Ordinary Ids
  LowercaseLetter -> True
  OtherLetter     -> True   -- See #1103
  _               -> False
startsConId c  = isUpper c || c == '('  -- Ordinary type constructors and data constructors

startsVarSymASCII :: Char -> Bool
startsVarSymASCII c = c `elem` "!#$%&*+./<=>?@\\^|~-"

isVarSymChar :: Char -> Bool
isVarSymChar c = c == ':' || startsVarSym c
