-- Imports a sibling module (SiblingA.hs) that has no .hu file.
module Main where
import Dialogue (stdout, appendChan, done, abort)

import SiblingA

main = appendChan stdout (greeting ++ "\n") abort done
