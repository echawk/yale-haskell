{-# LANGUAGE PatternSynonyms, TypeFamilies #-}
module Main where
import PatConExportA (Mode, pattern ScopeCheck, pattern TypeCheck, ToC, ConOf)
import qualified PatConExportA as PA

f :: ToC a => a -> ConOf a
f = PA.toC

main :: IO ()
main = print (ScopeCheck, TypeCheck == TypeCheck, f True)
