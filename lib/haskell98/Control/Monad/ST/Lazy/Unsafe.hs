-- Control.Monad.ST.Lazy.Unsafe (base); lazy ST is strict ST here
-- (Control.Monad.ST.Lazy).
module Control.Monad.ST.Lazy.Unsafe (unsafeInterleaveST, unsafeIOToST) where

import Control.Monad.ST.Unsafe (unsafeInterleaveST, unsafeIOToST)
