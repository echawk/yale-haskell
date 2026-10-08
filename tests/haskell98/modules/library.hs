-- Imports YaleTestLib, found as $HASKELL_LIBRARY/YaleTestLib.hu.
module Main where
import Dialogue (stdout, appendChan, done, abort)

import YaleTestLib

main = appendChan stdout (yaleTestLib ++ "\n") abort done
