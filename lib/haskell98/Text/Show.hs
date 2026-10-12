-- Text.Show (base)
module Text.Show (Show(showsPrec, show, showList), ShowS, shows, showChar,
                  showString, showParen, showListWith) where

showListWith :: (a -> ShowS) -> [a] -> ShowS
showListWith _ [] s = "[]" ++ s
showListWith showx (x : xs) s = '[' : showx x (showl xs)
  where showl [] = ']' : s
        showl (y : ys) = ',' : showx y (showl ys)
