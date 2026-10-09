-- Data.Version (base), for Yale Haskell's Haskell 98 dialect.  As in
-- base, versions compare by their branch only (tags are deprecated).
module Data.Version (
    Version(Version, versionBranch, versionTags), showVersion, parseVersionString,
    makeVersion
  ) where

import Data.List (intercalate, sort)
import Data.Char (isDigit)

data Version = Version { versionBranch :: [Int], versionTags :: [String] }
  deriving (Read, Show)

instance Eq Version where
  v1 == v2 = versionBranch v1 == versionBranch v2
             && sort (versionTags v1) == sort (versionTags v2)

instance Ord Version where
  v1 `compare` v2 = versionBranch v1 `compare` versionBranch v2

showVersion :: Version -> String
showVersion (Version branch tags) =
  intercalate "." (map show branch) ++ concatMap ('-':) tags

makeVersion :: [Int] -> Version
makeVersion b = Version b []

-- "1.2.3" to a Version (base's parseVersion is a ReadP parser; ReadP is
-- not here yet)
parseVersionString :: String -> Maybe Version
parseVersionString s = case go s of
                         Just b | not (null b) -> Just (makeVersion b)
                         _ -> Nothing
  where go str = case span isDigit str of
                   ("", _)       -> Nothing
                   (ds, "")      -> Just [read ds]
                   (ds, '.':r)   -> fmap (read ds :) (go r)
                   _             -> Nothing
