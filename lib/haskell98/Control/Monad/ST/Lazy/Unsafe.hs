-- Control.Monad.ST.Lazy.Unsafe (base), on Control.Monad.ST.Lazy's ST.
module Control.Monad.ST.Lazy.Unsafe (unsafeInterleaveST, unsafeIOToST) where

import qualified Control.Monad.ST.Unsafe as U
import Control.Monad.ST.Lazy (ST, strictToLazyST, lazyToStrictST)

unsafeInterleaveST :: ST s a -> ST s a
unsafeInterleaveST = strictToLazyST . U.unsafeInterleaveST . lazyToStrictST

unsafeIOToST :: IO a -> ST s a
unsafeIOToST = strictToLazyST . U.unsafeIOToST
