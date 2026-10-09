-- Foreign.Marshal.Unsafe (Haskell 2010 library, as in GHC's base): run an
-- IO action that only allocates and frees local memory as a pure value.
module Foreign.Marshal.Unsafe (unsafeLocalState) where

import ForeignPrims

unsafeLocalState :: IO a -> a
unsafeLocalState = primUnsafePerformIO
