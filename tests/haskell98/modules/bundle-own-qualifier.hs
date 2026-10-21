{-# LANGUAGE PatternSynonyms #-}
import BundleOwnQualA
f :: Q -> Int
f None = 0
f (Some n) = n
main = print (f None, f (Some 4))
