module ReexportAliasCompat (module Imports, module ReexportAliasCompat) where
import Prelude as Imports hiding (length, null, foldr, sum)
import Data.Foldable as Imports
import Data.Maybe as Imports
twice :: Int -> Int
twice = (* 2)
