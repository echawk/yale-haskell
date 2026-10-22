{-# LANGUAGE PatternSynonyms #-}
module Main where
import RecordSynonymA
f :: Defn -> Defn
f d = case d of
  Primitive{ primClauses = cs } -> d { primClauses = map (+1) cs }
  Other -> d
main = print (f (Primitive 1 [2,3]), primName (Primitive 5 []))
