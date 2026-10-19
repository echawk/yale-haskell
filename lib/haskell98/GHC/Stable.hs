{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.Stable (base): a StablePtr and a StablePtr# (GHC.PrimOps) are
-- converted into each other as they are; they are two kinds of stable
-- pointer here, so one made as either should only be used as that kind.
module GHC.Stable (
    StablePtr(StablePtr), newStablePtr, deRefStablePtr,
    freeStablePtr, castStablePtrToPtr, castPtrToStablePtr
  ) where

import GHC.PrimOps (StablePtr#)
import Foreign.StablePtr (StablePtr, newStablePtr, deRefStablePtr, freeStablePtr,
                          castStablePtrToPtr, castPtrToStablePtr)
import Unsafe.Coerce (unsafeCoerce)

pattern StablePtr :: StablePtr# a -> StablePtr a
pattern StablePtr p <- (unsafeCoerce -> p)
  where StablePtr p = unsafeCoerce p
