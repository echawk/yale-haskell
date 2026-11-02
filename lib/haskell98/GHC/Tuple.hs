{-# LANGUAGE PatternSynonyms #-}
-- GHC.Tuple (ghc-prim): the one-tuple, with the Solo pattern bundled
-- as in base 4.18, and getSolo (Data.Tuple's since base 4.19 only: QuickCheck
-- defines its own for 4.18).
module GHC.Tuple (Solo(MkSolo, Solo), getSolo) where

import Data.Tuple (Solo(MkSolo), pattern Solo)

getSolo :: Solo a -> a
getSolo (MkSolo a) = a
