-- Foreign.Concurrent (base): ForeignPtrs with Haskell finalizers.
module Foreign.Concurrent (newForeignPtr, addForeignPtrFinalizer) where

import Foreign.Ptr (Ptr)
import Foreign.ForeignPtr (ForeignPtr, newForeignPtr_, addForeignPtrFinalizerIO)

newForeignPtr :: Ptr a -> IO () -> IO (ForeignPtr a)
newForeignPtr p fin = do
  fp <- newForeignPtr_ p
  addForeignPtrFinalizerIO fp fin
  return fp

addForeignPtrFinalizer :: ForeignPtr a -> IO () -> IO ()
addForeignPtrFinalizer = addForeignPtrFinalizerIO
