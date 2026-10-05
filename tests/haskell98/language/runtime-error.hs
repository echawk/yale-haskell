-- error stops the program with a nonzero exit status; output produced
-- before the error is still written.
module Main where

out :: String
out = "before\n" ++ error "stop here" ++ "after\n"

main = appendChan stdout out abort done
