{-# LANGUAGE ForeignFunctionInterface #-}
-- Newtypes cross as their fields (Haskell 2010 8.4.2): CLong, CULong
-- (over Int64, Word64), a newtype of a Ptr (zlib's StreamState), ConstPtr
module Main (main) where
import Foreign.C.Types
import Foreign.C.String (CString, newCString, peekCString)
import Foreign.C.ConstPtr (ConstPtr(..))
import Foreign.Ptr (Ptr, castPtr)

newtype Handle = Handle (Ptr Handle)

foreign import ccall unsafe "labs" c_labs :: CLong -> IO CLong
foreign import ccall unsafe "labs" c_labsu :: CULong -> IO CULong
foreign import ccall unsafe "strlen" c_strlen :: Handle -> IO CSize
foreign import ccall unsafe "strchr" c_strchr :: ConstPtr CChar -> CInt -> IO (ConstPtr CChar)

main :: IO ()
main = do
  c_labs (-5) >>= print
  c_labsu 7 >>= print
  s <- newCString "hello"
  c_strlen (Handle (castPtr s)) >>= print
  ConstPtr p <- c_strchr (ConstPtr s) 108
  peekCString p >>= putStrLn
