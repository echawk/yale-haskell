-- Control.Monad.ST (base): the strict state-thread monad, over IO.
--
-- runST's type is the Haskell 98 one, ST s a -> a: without rank-2 types
-- it cannot be (forall s. ST s a) -> a, so nothing stops an STRef from
-- escaping its runST.  Programs that typecheck with base's runST run the
-- same here.
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

runST :: ST s a -> a
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
