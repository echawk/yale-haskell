-- UnliftedFFITypes: a byte array passed to C is its contents (bitvec's
-- omp_popcount, double-conversion's buffers).
{-# LANGUAGE MagicHash, UnboxedTuples, UnliftedFFITypes #-}
import GHC.Exts
import GHC.IO (IO(..))
import Foreign.C.Types
import GHC.Word (Word8(..))

foreign import ccall unsafe "string.h memset"
  c_memset :: MutableByteArray# RealWorld -> CInt -> CSize -> IO ()
foreign import ccall unsafe "string.h strnlen"
  c_strnlen :: ByteArray# -> CSize -> CSize

main :: IO ()
main = do
  n <- IO (\s -> case newByteArray# 8# s of
             (# s1, mb #) -> case c_memset' mb s1 of
               s2 -> case writeWord8Array# mb 5# 0 s2 of
                 s3 -> case unsafeFreezeByteArray# mb s3 of
                   (# s4, b #) -> (# s4, (c_strnlen b 8, W8# (indexWord8Array# b 0#)) #))
  print n
  where c_memset' mb s = case c_memset mb 65 8 of IO f -> case f s of (# s', () #) -> s'
