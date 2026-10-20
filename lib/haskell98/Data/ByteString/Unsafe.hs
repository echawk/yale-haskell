{-# LANGUAGE MagicHash #-}
-- Data.ByteString.Unsafe (bytestring): the operations without bounds
-- checks, here the checked ones (a ByteString is a packed string), and
-- the C-string conversions (copies: Data.ByteString's).
module Data.ByteString.Unsafe (
    unsafeHead, unsafeTail, unsafeInit, unsafeLast, unsafeIndex,
    unsafeTake, unsafeDrop,
    unsafeUseAsCString, unsafeUseAsCStringLen,
    unsafePackCString, unsafePackCStringLen,
    unsafePackMallocCString, unsafePackMallocCStringLen,
    unsafePackCStringFinalizer, unsafeFinalize,
    unsafePackAddress, unsafePackAddressLen
  ) where

import qualified Data.ByteString as B
import Data.ByteString (ByteString)
import Data.Word (Word8)
import Foreign.C.String (CString, CStringLen)
import Foreign.Ptr (Ptr)
import Foreign.Marshal.Alloc (free)
import GHC.Exts (Addr#, Ptr(Ptr))

unsafeHead :: ByteString -> Word8
unsafeHead = B.head

unsafeTail :: ByteString -> ByteString
unsafeTail = B.tail

unsafeInit :: ByteString -> ByteString
unsafeInit = B.init

unsafeLast :: ByteString -> Word8
unsafeLast = B.last

unsafeIndex :: ByteString -> Int -> Word8
unsafeIndex = B.index

unsafeTake :: Int -> ByteString -> ByteString
unsafeTake = B.take

unsafeDrop :: Int -> ByteString -> ByteString
unsafeDrop = B.drop

unsafeUseAsCString :: ByteString -> (CString -> IO a) -> IO a
unsafeUseAsCString = B.useAsCString

unsafeUseAsCStringLen :: ByteString -> (CStringLen -> IO a) -> IO a
unsafeUseAsCStringLen = B.useAsCStringLen

unsafePackCString :: CString -> IO ByteString
unsafePackCString = B.packCString

unsafePackCStringLen :: CStringLen -> IO ByteString
unsafePackCStringLen = B.packCStringLen

-- | The bytes are copied, and the C string freed.
unsafePackMallocCString :: CString -> IO ByteString
unsafePackMallocCString p = do { b <- B.packCString p; free p; return b }

unsafePackMallocCStringLen :: CStringLen -> IO ByteString
unsafePackMallocCStringLen (p, n) = do { b <- B.packCStringLen (p, n); free p; return b }

-- | The bytes are copied, and the finalizer run at once.
unsafePackCStringFinalizer :: Ptr Word8 -> Int -> IO () -> IO ByteString
unsafePackCStringFinalizer p n fin = do
  b <- B.packCStringLen (castW8 p, n)
  fin
  return b
  where castW8 :: Ptr Word8 -> CString
        castW8 q = case q of Ptr a -> Ptr a

unsafeFinalize :: ByteString -> IO ()
unsafeFinalize _ = return ()

unsafePackAddress :: Addr# -> IO ByteString
unsafePackAddress a = B.packCString (Ptr a)

unsafePackAddressLen :: Int -> Addr# -> IO ByteString
unsafePackAddressLen n a = B.packCStringLen (Ptr a, n)
