-- GHC.Show (base): the Show class and the helpers derived Show
-- instances and pretty printers use, written from base's interface.
module GHC.Show (
    Show(showsPrec, show, showList), ShowS,
    shows, showChar, showString, showParen, showList__, showCommaSpace,
    showSpace, showMultiLineString, showLitString, showLitChar,
    showSignedInt, appPrec, appPrec1, protectEsc, intToDigit
  ) where

import Data.Char (showLitChar, intToDigit)

-- the precedence of function application, and one more
appPrec, appPrec1 :: Int
appPrec = 10
appPrec1 = 11

showSpace :: ShowS
showSpace = showChar ' '

showCommaSpace :: ShowS
showCommaSpace = showString ", "

-- a list shown with the elements' function: [a,b,c]
showList__ :: (a -> ShowS) -> [a] -> ShowS
showList__ _ [] s = "[]" ++ s
showList__ showx (x : xs) s = '[' : showx x (showl xs)
  where showl [] = ']' : s
        showl (y : ys) = ',' : showx y (showl ys)

showSignedInt :: Int -> Int -> ShowS
showSignedInt = showsPrec

-- a string's characters as in a literal, without the quotes
showLitString :: String -> ShowS
showLitString [] s = s
showLitString ('"' : cs) s = showString "\\\"" (showLitString cs s)
showLitString (c : cs) s = showLitChar c (showLitString cs s)

-- a string over several lines, as a literal with gaps: each line but the
-- last ends with \n\, the next starts with \
showMultiLineString :: String -> [String]
showMultiLineString str = go '"' str
  where
    go ch s = case break (== '\n') s of
      (l, _ : s'@(_ : _)) -> (ch : showLitString l "\\n\\") : go '\\' s'
      (l, "\n") -> [ch : showLitString l "\\n\""]
      (l, _) -> [ch : showLitString l "\""]

-- an escape followed by a character that would continue it
protectEsc :: (Char -> Bool) -> ShowS -> ShowS
protectEsc p f = f . cont
  where cont s@(c : _) | p c = "\\&" ++ s
        cont s = s
