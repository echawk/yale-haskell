{-# LANGUAGE TemplateHaskell #-}
-- Data.FileEmbed (file-embed), the common part: a file's contents as a
-- ByteString literal at compile time (embedFile) through Template
-- Haskell's runIO; a path is relative to the package being built, the
-- directory the compiler runs in (makeRelativeToProject).
module Data.FileEmbed (
    embedFile, embedStringFile, embedDir, makeRelativeToProject,
    makeRelativeToLocationPredicate
  ) where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax (lift)
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as B8
import System.Directory (listDirectory, doesDirectoryExist)
import Control.Monad (forM)

embedFile :: FilePath -> Q Exp
embedFile fp = do
  s <- runIO (B.readFile fp)
  [| B8.pack $(lift (B8.unpack s)) |]

-- the file's text as a String (IsString at any type)
embedStringFile :: FilePath -> Q Exp
embedStringFile fp = do
  s <- runIO (readFile fp)
  lift s

embedDir :: FilePath -> Q Exp
embedDir dir = do
  files <- runIO (walk dir "")
  ps <- forM files (\f -> do
          s <- runIO (B.readFile (dir ++ "/" ++ f))
          [| ($(lift f), B8.pack $(lift (B8.unpack s))) |])
  return (ListE ps)
  where
    walk d rel = do
      names <- listDirectory (if null rel then d else d ++ "/" ++ rel)
      fmap concat $ forM names $ \n -> do
        let r = if null rel then n else rel ++ "/" ++ n
        isDir <- doesDirectoryExist (d ++ "/" ++ r)
        if isDir then walk d r else return [r]

makeRelativeToProject :: FilePath -> Q FilePath
makeRelativeToProject = return

makeRelativeToLocationPredicate :: (FilePath -> Bool) -> FilePath -> Q FilePath
makeRelativeToLocationPredicate _ = return
