-- Using == on a type with no Eq instance is a static error.
module Main where

data T = A | B

main = appendChan stdout (if A == B then "yes" else "no") abort done
