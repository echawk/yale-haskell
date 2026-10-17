-- Text.Read.Lex (base): Haskell lexemes, for ReadPrec readers.  Built on
-- the Prelude's lex: each token it returns is classified.
module Text.Read.Lex (
    Lexeme(Char, String, Punc, Ident, Symbol, Number, EOF), Number,
    numberToInteger, numberToRational, numberToRangedRational, lex, expect,
    hsLex, readIntP, readOctP, readDecP, readHexP
  ) where

import Prelude hiding (lex)
import qualified Prelude as P
import Data.Char (isAlpha, isDigit, isSpace, isOctDigit, isHexDigit, digitToInt)
import Data.Ratio ((%))
import Text.ParserCombinators.ReadP (ReadP, readS_to_P, munch1)
import qualified Text.ParserCombinators.ReadP as R

data Lexeme = Char Char | String String | Punc String | Ident String
            | Symbol String | Number Number | EOF
  deriving (Eq, Show)

-- a numeric literal, kept exact
data Number = MkNumber Rational Bool   -- the value; whether it was written with a point or exponent
  deriving (Eq, Show)

numberToInteger :: Number -> Maybe Integer
numberToInteger (MkNumber r False) = Just (truncate r)
numberToInteger _ = Nothing

numberToRational :: Number -> Rational
numberToRational (MkNumber r _) = r

numberToRangedRational :: (Int, Int) -> Number -> Maybe Rational
numberToRangedRational _ n = Just (numberToRational n)

-- one lexeme, after white space
lex :: ReadP Lexeme
lex = readS_to_P lexS

hsLex :: ReadP String
hsLex = readS_to_P P.lex

expect :: Lexeme -> ReadP ()
expect l = lex >>= \x -> if x == l then return () else R.pfail

lexS :: ReadS Lexeme
lexS s = case dropWhile isSpace s of
  "" -> [(EOF, "")]
  _ -> [ (classify tok, rest) | (tok, rest) <- P.lex s, tok /= "" ]

classify :: String -> Lexeme
classify tok@(c : _)
  | c == '\'' = case reads tok of
                  [(ch, "")] -> Char ch
                  _ -> Punc tok
  | c == '"' = case reads tok of
                 [(str, "")] -> String str
                 _ -> Punc tok
  | tok `elem` ["(", ")", ",", ";", "[", "]", "`", "{", "}"] = Punc tok
  | tok `elem` ["..", "::", "=", "\\", "|", "<-", "->", "@", "~", "=>"] = Punc tok
  | isAlpha c || c == '_' = Ident tok
  | isDigit c = Number (number tok)
  | otherwise = Symbol tok
classify "" = EOF

number :: String -> Number
number tok = case reads tok :: [(Integer, String)] of
  [(i, "")] -> MkNumber (fromInteger i) False
  _ -> case reads tok :: [(Double, String)] of
         [(d, "")] -> MkNumber (exactDecimal tok d) True
         _ -> MkNumber 0 False

-- the decimal literal's exact value (reads of a Double is close enough
-- only as a fallback)
exactDecimal :: String -> Double -> Rational
exactDecimal tok d =
  let (ip, rest) = span isDigit tok
      (fp, rest') = case rest of
                      ('.' : r) -> span isDigit r
                      _ -> ("", rest)
      ex = case rest' of
             (e : r) | e `elem` "eE" -> case r of
                                          ('-' : ds) -> negate (read ds)
                                          ('+' : ds) -> read ds
                                          ds -> read ds
             _ -> 0 :: Integer
      mant = read (ip ++ fp) % (10 ^ length fp) :: Rational
  in if null ip then toRational d
     else if ex >= 0 then mant * (10 ^ ex) else mant / (10 ^ negate ex)

readIntP :: Num a => a -> (Char -> Bool) -> (Char -> Int) -> ReadP a
readIntP base isDig valDigit =
  munch1 isDig >>= \ds -> return (foldl (\n d -> n * base + fromIntegral (valDigit d)) 0 ds)

readOctP, readDecP, readHexP :: (Eq a, Num a) => ReadP a
readOctP = readIntP 8 isOctDigit digitToInt
readDecP = readIntP 10 isDigit digitToInt
readHexP = readIntP 16 isHexDigit digitToInt
