{-# LANGUAGE PatternSynonyms #-}
module BundleOwnQualA (Q (BundleOwnQualA.None, Some)) where
data Q = Some Int | Other
pattern None :: Q
pattern None = Other
