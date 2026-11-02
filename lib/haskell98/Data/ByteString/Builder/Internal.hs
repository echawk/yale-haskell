-- Data.ByteString.Builder.Internal (bytestring): the part packages use
-- (conduit's flush); Yale Haskell's Builder has no buffers to flush.
module Data.ByteString.Builder.Internal (
    Builder, flush, toLazyByteStringWith, AllocationStrategy,
    safeStrategy, untrimmedStrategy, smallChunkSize, defaultChunkSize
  ) where

import Data.ByteString.Builder (Builder)
import Data.ByteString.Builder.Extra
