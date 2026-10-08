-- Haskell 98 export/import forms: a synonym by its bare name, and a
-- datatype or class with only some of its constituents (Shape(Circle),
-- Pretty(pretty)).  Square and prettyList stay hidden.
module Main where
import Dialogue (stdout, appendChan, done, abort)

import PartialExp (Syn, Shape(Circle), Pretty(pretty), area)

r :: Syn
r = 2

main = appendChan stdout (unlines [pretty (Circle r), show (area (Circle r))]) abort done
