-- Using == on a type with no Eq instance is a static error.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data T = A | B

main = appendChan stdout (if A == B then "yes" else "no") abort done
