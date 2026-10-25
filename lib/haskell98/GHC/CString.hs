{-# LANGUAGE MagicHash #-}
-- GHC.CString (ghc-prim): C strings at an Addr# (GHC.Exts defines them).
module GHC.CString (
    unpackCString#, unpackAppendCString#, unpackFoldrCString#,
    unpackCStringUtf8#, unpackAppendCStringUtf8#, unpackFoldrCStringUtf8#,
    unpackNBytes#, cstringLength#
  ) where

import GHC.Exts
