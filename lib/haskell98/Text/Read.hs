-- Text.Read (base), for Yale Haskell's Haskell 98 dialect: the Haskell 98
-- reading functions and readMaybe/readEither, and the Prelude's Read class
-- (its Haskell 98 methods; base's readPrec and readListPrec are not there).
module Text.Read (Read(readsPrec, readList), ReadS, reads, read, readParen,
                  lex, readMaybe, readEither) where

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
