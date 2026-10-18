{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
module BundleA (Q (.., Nil, (:>)), fromL) where
data Q a = Q [a]
pattern Nil :: Q a
pattern Nil = Q []
pattern (:>) :: a -> Q a -> Q a
pattern x :> rest <- (uncons -> Just (x, rest))
uncons :: Q a -> Maybe (a, Q a)
uncons (Q (x:xs)) = Just (x, Q xs)
uncons _ = Nothing
fromL :: [a] -> Q a
fromL = Q
