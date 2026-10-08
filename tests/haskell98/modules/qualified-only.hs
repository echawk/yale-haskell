-- import qualified brings names in only qualified: unqualified size is
-- not in scope, so this is a compile error.
module Main where

import qualified QualA as A

main = print (size A.Leaf)
