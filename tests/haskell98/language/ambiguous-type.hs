-- show (read s) has an ambiguous type with no numeric class in the
-- context, so defaulting does not apply and it is a static error
-- (Haskell 98 section 4.3.4).
module Main where

main = appendChan stdout (show (read "1")) abort done
