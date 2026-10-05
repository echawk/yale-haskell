-- Char is Unicode (Haskell 98 section 6.1.2): character codes above
-- 255 in escapes, toEnum and fromEnum.  The output is ASCII only.
module Main where

lambda, euro :: Char
lambda = '\955'
euro   = toEnum 8364

out :: String
out = unlines [ show (fromEnum lambda, fromEnum euro)
              , show (length "\955x\8594y", fromEnum (last "abc\1114111"))
              , show (lambda < euro, euro == '\8364') ]

main = appendChan stdout out abort done
