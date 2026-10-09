-- Foreign.Marshal: the Haskell 2010 library module (Report 2010, chapter
-- 32), for Yale Haskell's Haskell 98 dialect.
module Foreign.Marshal (
    module Foreign.Marshal.Alloc, module Foreign.Marshal.Array,
    module Foreign.Marshal.Error, module Foreign.Marshal.Utils,
    unsafeLocalState
  ) where

import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Marshal.Error
import Foreign.Marshal.Utils
import Foreign.Marshal.Unsafe
