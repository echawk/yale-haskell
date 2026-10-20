{-# LANGUAGE MagicHash, PatternSynonyms, ViewPatterns #-}
-- GHC.ForeignPtr (base): ForeignPtr addr contents builds a ForeignPtr
-- with no finalizer at the address; the contents (what keeps the memory
-- alive in GHC) are not kept: a byte array whose address is taken is
-- never freed (src/base/primops-runtime.lisp).  As a pattern, the
-- contents are a PlainForeignPtr.
module GHC.ForeignPtr (
    ForeignPtr(ForeignPtr), ForeignPtrContents(..),
    unsafeForeignPtrToPtr, castForeignPtr, newForeignPtr_, mallocForeignPtrBytes,
    unsafeWithForeignPtr, withForeignPtr, touchForeignPtr,
    mallocPlainForeignPtrBytes, mallocPlainForeignPtrAlignedBytes,
    mallocForeignPtrAlignedBytes
  ) where

import GHC.PrimOps (Addr#, MutableByteArray#, RealWorld)
import Foreign.ForeignPtr (ForeignPtr, newForeignPtr_, castForeignPtr,
                           mallocForeignPtrBytes, withForeignPtr, touchForeignPtr,
                           unsafeForeignPtrToPtr)
import Foreign.Ptr (Ptr)
import Unsafe.Coerce (unsafeCoerce)
import System.IO.Unsafe (unsafePerformIO)
import Data.IORef (IORef)

data ForeignPtrContents
  = PlainForeignPtr (IORef ())
  | FinalPtr
  | MallocPtr (MutableByteArray# RealWorld) (IORef ())
  | PlainPtr (MutableByteArray# RealWorld)

fromAddr :: Addr# -> ForeignPtr a
fromAddr a = unsafePerformIO (newForeignPtr_ (unsafeCoerce a))

toAddr :: ForeignPtr a -> Addr#
toAddr fp = unsafeCoerce (unsafeForeignPtrToPtr fp)

pattern ForeignPtr :: Addr# -> ForeignPtrContents -> ForeignPtr a
pattern ForeignPtr a c <- ((\fp -> (toAddr fp, FinalPtr)) -> (a, c))
  where ForeignPtr a _ = fromAddr a

unsafeWithForeignPtr :: ForeignPtr a -> (Ptr a -> IO b) -> IO b
unsafeWithForeignPtr = withForeignPtr

-- GHC's plain variants keep no finalizer; here every one is malloc's,
-- whose alignment (16) is what Storable types ask for.
mallocPlainForeignPtrBytes :: Int -> IO (ForeignPtr a)
mallocPlainForeignPtrBytes = mallocForeignPtrBytes

mallocPlainForeignPtrAlignedBytes :: Int -> Int -> IO (ForeignPtr a)
mallocPlainForeignPtrAlignedBytes n _ = mallocForeignPtrBytes n

mallocForeignPtrAlignedBytes :: Int -> Int -> IO (ForeignPtr a)
mallocForeignPtrAlignedBytes n _ = mallocForeignPtrBytes n
