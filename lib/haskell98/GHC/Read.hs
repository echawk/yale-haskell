-- GHC.Read (base): helpers for ReadPrec readers.
module GHC.Read (
    Read(readsPrec, readList, readPrec, readListPrec), lexP, expectP, paren,
    parens, list, choose, readField, readFieldHash, readSymField,
    readListDefault, readListPrecDefault, readNumber, lexLitChar,
    readLitChar
  ) where

import PreludeCore (Read(readPrec, readListPrec))
import Text.ParserCombinators.ReadPrec
import qualified Text.Read.Lex as L
import Data.Char (lexLitChar, readLitChar)

lexP :: ReadPrec L.Lexeme
lexP = lift L.lex

expectP :: L.Lexeme -> ReadPrec ()
expectP lexeme = lexP >>= \thing -> if thing == lexeme then return () else pfail

-- the reader in parentheses
paren :: ReadPrec a -> ReadPrec a
paren p = expectP (L.Punc "(") >> reset p >>= \x -> expectP (L.Punc ")") >> return x

-- the reader, in any number of parentheses
parens :: ReadPrec a -> ReadPrec a
parens p = optional
  where optional = p +++ mandatory
        mandatory = paren optional

-- [x, y, ...], each read with the given reader
list :: ReadPrec a -> ReadPrec [a]
list readx = parens (expectP (L.Punc "[") >> (closeNow +++ elems))
  where closeNow = expectP (L.Punc "]") >> return []
        elems = reset readx >>= \x -> rest >>= \xs -> return (x : xs)
        rest = (expectP (L.Punc "]") >> return [])
               +++ (expectP (L.Punc ",") >> reset readx >>= \x -> rest >>= \xs -> return (x : xs))

-- one of the named alternatives (constructors without arguments)
choose :: [(String, ReadPrec a)] -> ReadPrec a
choose sps = foldr ((+++) . try_one) pfail sps
  where try_one (s, p) = lexP >>= \token -> case token of
                           L.Ident s' | s == s' -> p
                           L.Symbol s' | s == s' -> p
                           _ -> pfail

-- field = value, in a record
readField :: String -> ReadPrec a -> ReadPrec a
readField fieldName readVal =
  expectP (L.Ident fieldName) >> expectP (L.Punc "=") >> readVal

readFieldHash :: String -> ReadPrec a -> ReadPrec a
readFieldHash fieldName readVal =
  expectP (L.Ident fieldName) >> expectP (L.Symbol "#") >> expectP (L.Punc "=") >> readVal

readSymField :: String -> ReadPrec a -> ReadPrec a
readSymField fieldName readVal =
  expectP (L.Punc "(") >> expectP (L.Symbol fieldName) >> expectP (L.Punc ")")
    >> expectP (L.Punc "=") >> readVal

readListDefault :: Read a => ReadS [a]
readListDefault = readPrec_to_S readListPrec 0

readListPrecDefault :: Read a => ReadPrec [a]
readListPrecDefault = list readPrec

readNumber :: Num a => (L.Lexeme -> ReadPrec a) -> ReadPrec a
readNumber convert = parens (lexP >>= \x -> case x of
                               L.Symbol "-" -> step lexP >>= convert >>= \n -> return (negate n)
                               _ -> convert x)
