-- System.IO.Unsafe (base): running IO outside the IO monad.
module System.IO.Unsafe (
    unsafePerformIO, unsafeDupablePerformIO, unsafeInterleaveIO,
    unsafeDupableInterleaveIO, unsafeFixIO
  ) where

import BasePrims
import Data.IORef

unsafePerformIO :: IO a -> a
unsafePerformIO = primUnsafePerformIO

unsafeDupablePerformIO :: IO a -> a
unsafeDupablePerformIO = primUnsafePerformIO

-- The action runs when the result is first demanded.
unsafeInterleaveIO :: IO a -> IO a
unsafeInterleaveIO = primUnsafeInterleaveIO

unsafeDupableInterleaveIO :: IO a -> IO a
unsafeDupableInterleaveIO = primUnsafeInterleaveIO

-- fixIO without the check that the result is not demanded too early.
unsafeFixIO :: (a -> IO a) -> IO a
unsafeFixIO k = do
  ref <- newIORef (error "unsafeFixIO: the result was demanded too early")
  ans <- unsafeInterleaveIO (readIORef ref)
  result <- k ans
  writeIORef ref result
  return result
