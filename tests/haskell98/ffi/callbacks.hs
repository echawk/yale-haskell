-- "wrapper" imports and foreign export (Haskell 2010 8.4): libc qsort
-- calling back into Haskell, slots freed and reused, an export found
-- through an & import.
module Main where
import Foreign
import Foreign.C.Types

type Compare = Ptr CInt -> Ptr CInt -> IO CInt

foreign import ccall "wrapper" mkCompare :: Compare -> IO (FunPtr Compare)
foreign import ccall "stdlib.h qsort"
  qsort :: Ptr CInt -> CSize -> CSize -> FunPtr Compare -> IO ()
foreign import ccall "dynamic" callIntFun :: FunPtr (CInt -> CInt) -> CInt -> CInt
foreign import ccall "wrapper" mkIntFun :: (CInt -> CInt) -> IO (FunPtr (CInt -> CInt))
foreign import ccall "&descending" descendingPtr :: FunPtr Compare

foreign export ccall "descending" descending :: Compare
descending :: Compare
descending p q = do
  a <- peek p
  b <- peek q
  return (fromIntegral (fromEnum (compare b a)) - 1)

ascending :: Compare
ascending p q = do
  a <- peek p
  b <- peek q
  return (fromIntegral (fromEnum (compare a b)) - 1)

sortWith :: FunPtr Compare -> [CInt] -> IO [CInt]
sortWith cmp xs = withArrayLen xs $ \n p -> do
  qsort p (fromIntegral n) 4 cmp
  peekArray n p

main :: IO ()
main = do
  cmp <- mkCompare ascending
  sortWith cmp [5, 3, 9, 1, 7] >>= print
  freeHaskellFunPtr cmp
  sortWith descendingPtr [5, 3, 9, 1, 7] >>= print
  fs <- mapM (\k -> mkIntFun (* k)) [1 .. 5]
  print [callIntFun f 10 | f <- fs]
  mapM_ freeHaskellFunPtr fs
  g <- mkIntFun (+ 100)
  print (callIntFun g 1)
