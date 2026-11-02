-- GHC.ResponseFile (base): command-line arguments in @file response
-- files, quoted and escaped as gcc's are.
module GHC.ResponseFile (
    getArgsWithResponseFiles, unescapeArgs, escapeArgs, expandResponse
  ) where

import Control.Exception (IOException, try)
import Data.Char (isSpace)
import Data.List (foldl')
import System.Environment (getArgs)

getArgsWithResponseFiles :: IO [String]
getArgsWithResponseFiles = getArgs >>= expandResponse

-- | Each @file argument replaced by the arguments its file holds, read
-- with unescapeArgs (a file that cannot be read leaves the argument).
expandResponse :: [String] -> IO [String]
expandResponse = fmap concat . mapM expand
  where
    expand ('@' : f) = do
      r <- try (readFile f)
      case r of
        Left e -> const (return ['@' : f]) (e :: IOException)
        Right s -> expandResponse (unescapeArgs s)
    expand a = return [a]

-- | Arguments separated by white space, with '...' and "..." quoting and
-- \ escaping.
unescapeArgs :: String -> [String]
unescapeArgs = filter (not . null) . unescape

data Quoting = NoneQ | SngQ | DblQ

unescape :: String -> [String]
unescape args = reverse (map reverse (go args NoneQ False [] []))
  where
    go [] _ _ a as = a : as
    go (c : cs) q True a as = go cs q False (c : a) as
    go (c : cs) q False a as
      | c == '\\' = go cs q True a as
    go (c : cs) SngQ False a as
      | c == '\'' = go cs NoneQ False a as
      | otherwise = go cs SngQ False (c : a) as
    go (c : cs) DblQ False a as
      | c == '"' = go cs NoneQ False a as
      | otherwise = go cs DblQ False (c : a) as
    go (c : cs) NoneQ False a as
      | isSpace c = go cs NoneQ False [] (a : as)
      | c == '\'' = go cs SngQ False a as
      | c == '"' = go cs DblQ False a as
      | otherwise = go cs NoneQ False (c : a) as

-- | Arguments as a response file: one a line, white space, quotes and \
-- escaped.
escapeArgs :: [String] -> String
escapeArgs = unlines . map escapeArg

escapeArg :: String -> String
escapeArg = reverse . foldl' escape []
  where
    escape cs c
      | isSpace c || c == '\\' || c == '\'' || c == '"' = c : '\\' : cs
      | otherwise = c : cs
