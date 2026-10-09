-- Foreign: the Haskell 2010 library module (Report 2010, chapter 24), for
-- Yale Haskell's Haskell 98 dialect.  Foreign.ForeignPtr and
-- Foreign.StablePtr are missing.  loadForeignLibrary (not in the Report)
-- loads a C shared library for foreign imports, like yale-haskell -l.
module Foreign (
    module Data.Bits, module Data.Int, module Data.Word,
    module Foreign.Ptr, module Foreign.Storable, module Foreign.Marshal,
    loadForeignLibrary
  ) where

import Data.Bits
import Data.Int
import Data.Word
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal
import ForeignPrims

loadForeignLibrary :: String -> IO ()
loadForeignLibrary = primLoadLibrary
