-- Text.Regex (regex-compat): POSIX extended regular expressions, matched
-- by the host's cl-ppcre (src/base/base-runtime.lisp).
module Text.Regex (
    Regex, mkRegex, mkRegexWithOpts, matchRegex, matchRegexAll,
    subRegex, splitRegex
  ) where

import BasePrims (RegexObj, primRegexCompile, primRegexMatch)

data Regex = Regex RegexObj

mkRegex :: String -> Regex
mkRegex s = mkRegexWithOpts s True True

-- mkRegexWithOpts pattern multiline caseSensitive
mkRegexWithOpts :: String -> Bool -> Bool -> Regex
mkRegexWithOpts s multiline caseSensitive =
  Regex (primRegexCompile s caseSensitive multiline)

-- The whole match and the groups' texts, or Nothing.
match :: Regex -> String -> Maybe (String, [String])
match (Regex r) s = case primRegexMatch r s of
  [] -> Nothing
  enc -> case splitNul (drop 2 enc) of
           (whole : groups) -> Just (whole, groups)
           [] -> Just ("", [])

splitNul :: String -> [String]
splitNul s = case break (== '\0') s of
  (a, []) -> [a]
  (a, _ : rest) -> a : splitNul rest

matchRegex :: Regex -> String -> Maybe [String]
matchRegex r s = fmap snd (match r s)

-- The text before the match, the match, the text after and the groups.
matchRegexAll :: Regex -> String -> Maybe (String, String, String, [String])
matchRegexAll r s = case match r s of
  Nothing -> Nothing
  Just (whole, groups) ->
    let (before, after) = findSub whole s
    in Just (before, whole, after, groups)

-- The first occurrence of W in S that the scanner found (it matched there,
-- and leftmost): the text around it.
findSub :: String -> String -> (String, String)
findSub w s = go [] s
  where go acc t | take (length w) t == w = (reverse acc, drop (length w) t)
        go acc (c : t) = go (c : acc) t
        go acc [] = (reverse acc, [])

-- Replaces each match; \1 ... \9 in the replacement are the groups and
-- \0 the whole match.
subRegex :: Regex -> String -> String -> String
subRegex r s repl = case matchRegexAll r s of
  Nothing -> s
  Just (before, whole, after, groups)
    | null whole -> s
    | otherwise -> before ++ expand (whole : groups) repl ++ subRegex r after repl
  where expand gs ('\\' : d : rest) | d >= '0' && d <= '9' =
          let i = fromEnum d - fromEnum '0'
          in (if i < length gs then gs !! i else "") ++ expand gs rest
        expand gs (c : rest) = c : expand gs rest
        expand _ [] = []

splitRegex :: Regex -> String -> [String]
splitRegex r s = case matchRegexAll r s of
  Nothing -> [s]
  Just (before, whole, after, _)
    | null whole -> [s]
    | otherwise -> before : splitRegex r after
