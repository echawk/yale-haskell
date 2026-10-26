-- Data.Text.Read (text): reading numbers at the start of a Text; the
-- number and the rest, or a message.
module Data.Text.Read (
    Reader, decimal, hexadecimal, signed, rational, double
  ) where

import qualified Data.Text as T
import Data.Text (Text)
import Data.Char (isDigit, isHexDigit, digitToInt)

type Reader a = Text -> Either String (a, Text)

decimal :: Integral a => Reader a
decimal t =
  let (ds, rest) = T.span isDigit t
  in if T.null ds
       then Left "input does not start with a digit"
       else Right (T.foldl' (\n c -> n * 10 + fromIntegral (digitToInt c)) 0 ds, rest)

hexadecimal :: Integral a => Reader a
hexadecimal t0 =
  let t = maybe t0 id (T.stripPrefix (T.pack "0x") t0 `orElse` T.stripPrefix (T.pack "0X") t0)
      (ds, rest) = T.span isHexDigit t
  in if T.null ds
       then Left "input does not start with a hexadecimal digit"
       else Right (T.foldl' (\n c -> n * 16 + fromIntegral (digitToInt c)) 0 ds, rest)
  where orElse (Just x) _ = Just x
        orElse Nothing y = y

signed :: Num a => Reader a -> Reader a
signed f t = case T.uncons t of
  Just ('-', rest) -> fmap (\(n, r) -> (negate n, r)) (f rest)
  Just ('+', rest) -> f rest
  _ -> f t

rational :: Fractional a => Reader a
rational = floating

double :: Reader Double
double = floating

-- digits, an optional fraction and an optional exponent
floating :: Fractional a => Reader a
floating t = case signed decimal t of
  Left e -> Left e
  Right (whole, r1) ->
    let neg = T.take 1 t == T.pack "-"
        (frac, r2) = case T.uncons r1 of
          Just ('.', r) | not (T.null (T.takeWhile isDigit r)) ->
            let (fs, r') = T.span isDigit r in (fs, r')
          _ -> (T.empty, r1)
        (ex, r3) = case T.uncons r2 of
          Just (e, r) | e == 'e' || e == 'E' ->
            case signed decimal r of
              Right (n, r') -> (n :: Integer, r')
              Left _ -> (0, r2)
          _ -> (0, r2)
        fracValue = T.foldr (\c acc -> (fromIntegral (digitToInt c) + acc) / 10) 0 frac
        magnitude = fromInteger (abs whole) + fracValue
        signedValue = if neg || whole < 0 then negate magnitude else magnitude
    in Right (signedValue * (10 ^^ ex), r3)
