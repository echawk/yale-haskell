-- Haskell 2010 Foreign.ForeignPtr, Foreign.StablePtr, Foreign.C.Error and
-- IntPtr/WordPtr.
module Main where

import Foreign
import Foreign.C
import System.IO.Error (isDoesNotExistError, ioeGetFileName, try)

foreign import ccall "stdlib.h getenv" c_getenv :: CString -> IO (Ptr CChar)
foreign import ccall "unistd.h rmdir" c_rmdir :: CString -> IO CInt

main :: IO ()
main = do
  -- ForeignPtr: malloc'd memory freed by finalizerFree
  fp <- mallocForeignPtrArray 4 :: IO (ForeignPtr Int32)
  withForeignPtr fp $ \p -> pokeArray p [10, 20, 30, 40]
  xs <- withForeignPtr fp $ \p -> peekArray 4 p
  print (xs, fp == fp, castForeignPtr fp == (castForeignPtr fp :: ForeignPtr Word8))
  finalizeForeignPtr fp
  fp2 <- mallocForeignPtr :: IO (ForeignPtr Double)
  withForeignPtr fp2 $ \p -> poke p 2.5 >> peek p >>= print
  -- StablePtr
  sp <- newStablePtr (map (* 2) [1, 2, 3 :: Int])
  let p = castStablePtrToPtr sp
  v <- deRefStablePtr (castPtrToStablePtr p) :: IO [Int]
  print (v, p /= nullPtr)
  alloca $ \q -> do
    poke q sp
    sp' <- peek q
    (deRefStablePtr sp' :: IO [Int]) >>= print . sum
  freeStablePtr sp
  -- IntPtr / WordPtr
  let ip = ptrToIntPtr (nullPtr `plusPtr` 4096)
  print (ip, intPtrToPtr ip == nullPtr `plusPtr` 4096, ptrToWordPtr nullPtr)
  -- Foreign.C.Error
  print (eOK == eOK, isValidErrno eNOENT, eNOENT == eNOENT, eNOENT == eEXIST)
  r <- withCString "/no/such/dir" c_rmdir
  e <- getErrno
  print (r, e == eNOENT)
  res <- try (throwErrnoPathIfMinus1_ "rmdir" "/no/such/dir"
                (withCString "/no/such/dir" c_rmdir))
  case res of
    Left err -> print (isDoesNotExistError err, ioeGetFileName err)
    Right () -> putStrLn "no error"
  resetErrno
  getErrno >>= print . (== eOK)
  n <- withCString "YALE_NO_SUCH_VAR" c_getenv
  print (n == nullPtr)
