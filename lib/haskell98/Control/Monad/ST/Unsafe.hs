-- Control.Monad.ST.Unsafe (base).
module Control.Monad.ST.Unsafe (
    unsafeIOToST, unsafeSTToIO, unsafeInterleaveST, unsafeDupableInterleaveST
  ) where

import Control.Monad.ST (ST, unsafeIOToST, unsafeSTToIO)
import System.IO.Unsafe (unsafeInterleaveIO)

unsafeInterleaveST :: ST s a -> ST s a
unsafeInterleaveST m = unsafeIOToST (unsafeInterleaveIO (unsafeSTToIO m))

unsafeDupableInterleaveST :: ST s a -> ST s a
unsafeDupableInterleaveST = unsafeInterleaveST
