-- Text.Read (base), for Yale Haskell's Haskell 98 dialect: the Haskell 98
-- reading functions and readMaybe/readEither.  The Read class itself is
-- the Prelude's.
module Text.Read (reads, read, readParen, lex, readMaybe, readEither) where

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
