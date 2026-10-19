{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.STRef (base): an STRef is a MutVar# (GHC.PrimOps); Yale Haskell's
-- STRef (Data.STRef) is the same cell.
module GHC.STRef (
    STRef(STRef), newSTRef, readSTRef, writeSTRef
  ) where

import GHC.PrimOps (MutVar#)
import Data.STRef (STRef, newSTRef, readSTRef, writeSTRef)
import Unsafe.Coerce (unsafeCoerce)

pattern STRef :: MutVar# s a -> STRef s a
pattern STRef v <- (unsafeCoerce -> v)
  where STRef v = unsafeCoerce v
