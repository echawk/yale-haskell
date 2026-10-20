{-# LANGUAGE PatternSynonyms #-}
-- GHC.Tuple (ghc-prim): the one-tuple, with the Solo pattern bundled
-- as in base 4.18.
module GHC.Tuple (Solo(MkSolo, Solo), getSolo) where

import Data.Tuple (Solo(MkSolo), pattern Solo, getSolo)
