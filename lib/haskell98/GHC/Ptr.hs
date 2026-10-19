{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.Ptr (base): a Ptr is an Addr# (GHC.PrimOps): both are machine
-- addresses here.
module GHC.Ptr (
    Ptr(Ptr), FunPtr, nullPtr, castPtr, plusPtr, alignPtr, minusPtr,
    nullFunPtr, castFunPtr
  ) where

import GHC.Exts (Ptr(Ptr))
import Foreign.Ptr (FunPtr, nullPtr, castPtr, plusPtr, alignPtr, minusPtr,
                    nullFunPtr, castFunPtr)
