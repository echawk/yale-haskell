{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Exported pattern synonyms (pattern-synonyms.hs): a one-way synonym
-- through a view pattern with a two-clause builder, and a signature.
module PatSynViews (T(..), pattern L, pattern Two, pattern Pos) where

data T = N [Int] | A Int deriving Show

pattern Two :: Int
pattern Two = 2

pattern L :: [Int] -> T
pattern L xs <- N (reverse -> xs) where
  L [] = N []
  L xs = N (reverse xs)

-- nested views
pattern Pos :: Int -> Int
pattern Pos n <- (abs -> (subtract 0 -> n))
