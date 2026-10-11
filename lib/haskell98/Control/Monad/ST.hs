-- Control.Monad.ST (base): the strict state-thread monad, over IO.
--
-- runST's type is base's, (forall s. ST s a) -> a, though Yale
-- Haskell's rank-N types do not check the action's polymorphism
-- (src/compiler/type/polytypes.mumble): nothing stops an STRef from
-- escaping its runST.  Programs that typecheck with base run the same.
module Control.Monad.ST (
    ST, runST, fixST, RealWorld, stToIO, ioToST, unsafeIOToST, unsafeSTToIO
  ) where

import PreludeModern
import System.IO.Unsafe (unsafePerformIO, unsafeFixIO)

newtype ST s a = ST (IO a)

data RealWorld = RealWorld

unST :: ST s a -> IO a
unST (ST io) = io

instance Functor (ST s) where
  fmap f (ST io) = ST (fmap f io)

instance Applicative (ST s) where
  pure x = ST (return x)
  ST f <*> ST a = ST (f >>= \g -> a >>= \x -> return (g x))

instance Monad (ST s) where
  return x = ST (return x)
  ST m >>= k = ST (m >>= \x -> unST (k x))
  ST m >> ST n = ST (m >> n)
  {-# (>>=) :: Inline #-}
  {-# (>>) :: Inline #-}
  {-# return :: Inline #-}

runST :: (forall s. ST s a) -> a
runST (ST io) = unsafePerformIO io

fixST :: (a -> ST s a) -> ST s a
fixST k = ST (unsafeFixIO (\x -> unST (k x)))

stToIO :: ST RealWorld a -> IO a
stToIO (ST io) = io

ioToST :: IO a -> ST RealWorld a
ioToST = ST

unsafeIOToST :: IO a -> ST s a
unsafeIOToST = ST

unsafeSTToIO :: ST s a -> IO a
unsafeSTToIO (ST io) = io
