-- Foreign.StablePtr: the Haskell 2010 library module (Report 2010,
-- chapter 34), for Yale Haskell's Haskell 98 dialect.  A StablePtr is the
-- number of a value in a table (src/ffi/ffi-runtime.lisp), as a pointer;
-- freeStablePtr removes it, and the value can then be collected.
module Foreign.StablePtr (
    StablePtr, newStablePtr, deRefStablePtr, freeStablePtr,
    castStablePtrToPtr, castPtrToStablePtr
  ) where

import ForeignPrims
import Foreign.Ptr

newtype StablePtr a = StablePtr (Ptr ())

instance Eq (StablePtr a) where
  StablePtr p == StablePtr q = p == q

newStablePtr :: a -> IO (StablePtr a)
newStablePtr x = do
  p <- primNewStablePtr x
  return (StablePtr p)

deRefStablePtr :: StablePtr a -> IO a
deRefStablePtr (StablePtr p) = primDerefStablePtr p

freeStablePtr :: StablePtr a -> IO ()
freeStablePtr (StablePtr p) = primFreeStablePtr p

castStablePtrToPtr :: StablePtr a -> Ptr ()
castStablePtrToPtr (StablePtr p) = p

castPtrToStablePtr :: Ptr () -> StablePtr a
castPtrToStablePtr p = StablePtr p
