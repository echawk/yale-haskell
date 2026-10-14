-- What Cabal generates for happy: its version, and its data directory
-- (the templates) from $happy_datadir.
module Paths_happy (version, getDataDir) where

import Data.Version (Version, makeVersion)
import System.Environment (lookupEnv)

version :: Version
version = makeVersion [1, 20, 1, 1]

getDataDir :: IO FilePath
getDataDir = fmap (maybe "data" id) (lookupEnv "happy_datadir")
