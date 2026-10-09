-- Re-exporting Prelude data types with their constructors from a module
-- that imports the Prelude implicitly, and a module with an empty body.
module Main where

import ReexPrelude (Maybe(Nothing, Just), Either(Left), Ordering(..))
import qualified Data.Maybe as M (Maybe(..), fromMaybe)

main :: IO ()
main = do
  print (Just True, Left 1 :: Either Int Int, compare 1 2 == LT)
  print (M.fromMaybe 0 (M.Just 5), M.Nothing :: M.Maybe Int)
