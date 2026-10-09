module Main where
import Foreign
import Foreign.C
import Foreign.Marshal.Unsafe (unsafeLocalState)

foreign import ccall "string.h strlen" c_strlen :: CString -> IO CSize
foreign import ccall "stdlib.h qsort" c_qsort :: Ptr CInt -> CSize -> CSize -> FunPtr (Ptr CInt -> Ptr CInt -> IO CInt) -> IO ()
foreign import ccall "stdlib.h &abs" p_abs :: FunPtr (CInt -> CInt)
foreign import ccall "dynamic" callIntFun :: FunPtr (CInt -> CInt) -> CInt -> CInt
foreign import ccall "math.h frexp" c_frexp :: CDouble -> Ptr CInt -> IO CDouble
foreign import ccall "memset" c_memset :: Ptr Word8 -> CInt -> CSize -> IO (Ptr Word8)
foreign import ccall "abs" c_abs :: CInt -> CInt

-- a pure function built from local allocation
frexp :: Double -> (Double, Int)
frexp x = unsafeLocalState $ alloca $ \pe -> do
  m <- c_frexp (realToFrac x) pe
  e <- peek pe
  return (realToFrac m, fromIntegral e)

main :: IO ()
main = do
  n <- withCString "hello, world" c_strlen
  print n
  print (c_abs (-7), frexp 8.0)
  -- arrays
  xs <- withArray [5, 3, 9, 1 :: CInt] $ \p -> do
          poke (advancePtr p 1) 42
          peekArray 4 p
  print xs
  p <- mallocArray 8 :: IO (Ptr Word8)
  _ <- c_memset p 255 8
  ws <- peekArray 8 p
  print (sum (map fromIntegral ws :: [Int]))
  free p
  -- Storable round trips
  print =<< with (3.25 :: Double) peek
  print =<< with 'λ' peek
  print =<< with True peek
  print =<< with (minBound :: Int64) peek
  print =<< with (maxBound :: Word16) peek
  q <- new (12345 :: Int)
  print =<< peek q
  print (q == q, nullPtr == (nullPtr :: Ptr Int), q `minusPtr` q, plusPtr q 8 `minusPtr` q)
  free q
  -- strings
  s <- newCString "naïve ☃"
  print =<< peekCString s
  print =<< peekCStringLen (s, 4)
  free s
  (s2, len) <- newCStringLen "αβγ"
  print len
  free s2
  -- calling through a FunPtr
  print (callIntFun p_abs (-99), p_abs /= nullFunPtr)
  print =<< withCString "a\255b" (\p -> peekCString p >>= return . length)
  print (sizeOf (0 :: CInt), sizeOf (0 :: CLong), alignment (0 :: Double), sizeOf nullPtr)
