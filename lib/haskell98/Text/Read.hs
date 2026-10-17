-- Text.Read (base): the Read class (the Prelude's, with base's ReadPrec
-- methods), reading functions, and ReadPrec readers.
module Text.Read (
    Read(readsPrec, readList, readPrec, readListPrec), ReadS, reads, read,
    readParen, lex, readMaybe, readEither,
    module Text.ParserCombinators.ReadPrec,
    Lexeme(..), lexP, parens, readListDefault, readListPrecDefault
  ) where

import PreludeCore (Read(readPrec, readListPrec))
import Text.ParserCombinators.ReadPrec
import Text.Read.Lex (Lexeme(..))
import GHC.Read (lexP, parens, readListDefault, readListPrecDefault)

readEither :: Read a => String -> Either String a
readEither s =
  case [ x | (x, rest) <- reads s, ("", "") <- lex rest ] of
    [x] -> Right x
    []  -> Left "Prelude.read: no parse"
    _   -> Left "Prelude.read: ambiguous parse"

readMaybe :: Read a => String -> Maybe a
readMaybe s = case readEither s of
                Left _  -> Nothing
                Right a -> Just a
