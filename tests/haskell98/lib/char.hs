-- The Char library (ASCII and Latin-1 behaviour).
module Main where

import Char

str :: String
str = "aZ09 \t\nfF!_~\DEL\160\200\233\215\247"

main = appendChan stdout (unlines [
  show (map isHexDigit "09afAFgG", map isOctDigit "078"),
  show (map digitToInt "09afAF", map intToDigit [0, 9, 10, 15]),
  show (map isAlphaNum str),
  show (map isAlpha str),
  show (map isUpper str, map isLower str),
  show (map isSpace str),
  show (map isControl str, map isPrint str),
  show (map isAscii str, all isLatin1 str),
  show (map toUpper str, map toLower str),
  show (ord 'a', chr 66, map (chr . (+ 1) . ord) "HAL"),
  show (readLitChar "\\nabc", readLitChar "\\x41z", readLitChar "\\SOHx", readLitChar "\\o101", readLitChar "\\^Ax"),
  show (lexLitChar "\\nabc", lexLitChar "\\123x", lexLitChar "a"),
  showLitChar '\n' (showLitChar '\DEL' (showLitChar '\200' "")),
  show (read "'\\t'" :: Char, read "\"a\\SOH\\&H\"" :: String)
  ]) abort done
