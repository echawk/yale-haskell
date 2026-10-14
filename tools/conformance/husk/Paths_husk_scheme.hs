-- What Cabal generates for husk-scheme: its version, and its data files
-- (lib/) beside the program or in $husk_scheme_datadir.
module Paths_husk_scheme (version, getDataFileName) where

import Data.Version (Version, makeVersion)
import System.Environment (lookupEnv)

version :: Version
version = makeVersion [3, 20]

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- lookupEnv "husk_scheme_datadir"
  return (maybe "." id dir ++ "/" ++ name)
