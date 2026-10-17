{-# LANGUAGE PatternSynonyms #-}
import Data.List.NonEmpty (NonEmpty, pattern (:|), toList)
f :: NonEmpty Int -> Int
f (x :| _) = x
main = print (f (1 :| [2]), toList (3 :| []))
