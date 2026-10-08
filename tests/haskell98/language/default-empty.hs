-- With 'default ()' no defaulting takes place, so the ambiguous type
-- of 1 + 2 is a static error (Haskell 98 section 4.3.4).
module Main where
import Dialogue (stdout, appendChan, done, abort)

default ()

main = appendChan stdout (show (1 + 2)) abort done
