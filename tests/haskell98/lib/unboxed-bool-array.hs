-- Unboxed arrays of Bool are bit vectors (Data.Array.Base's newArray,
-- base-runtime.lisp's prim.new-unboxed-mut-arr); reading, writing,
-- freezing, thawing, (//), accumulating and comparing them give what
-- boxed arrays give.  Arrays of other element types are unchanged.
import Control.Monad
import Control.Monad.ST
import Data.Array.ST
import Data.Array.IO
import Data.Array.Unboxed

sieve :: Int -> UArray Int Bool
sieve n = runSTUArray $ do
  a <- newArray (2, n) True
  forM_ [2 .. n] $ \i -> do
    p <- readArray a i
    when (p && i * i <= n) $ forM_ [i * i, i * i + i .. n] $ \j -> writeArray a j False
  return a

main :: IO ()
main = do
  let s = sieve 100
  print [i | (i, True) <- assocs s]
  print (bounds s, s ! 97, s ! 98, length (filter id (elems s)))
  let s2 = s // [(4, True), (5, False)]
  print (s2 ! 4, s2 ! 5, s ! 4, s ! 5)
  print (s == s, s == s2, take 5 (elems s2))
  io <- newArray (0, 9) False :: IO (IOUArray Int Bool)
  forM_ [0, 3 .. 9] $ \i -> writeArray io i True
  getElems io >>= print
  fz <- freeze io :: IO (UArray Int Bool)
  print fz
  th <- thaw fz :: IO (IOUArray Int Bool)
  writeArray th 1 True
  getElems th >>= print
  print (fz ! 1)
  b <- newArray_ (1, 3) :: IO (IOUArray Int Bool)
  forM_ [1 .. 3] $ \i -> writeArray b i (odd i)
  getElems b >>= print
  ints <- newArray (1, 4) 7 :: IO (IOUArray Int Int)
  writeArray ints 2 9
  getElems ints >>= print
  print (accumArray (||) False (0, 4) [(1, True), (3, True)] :: UArray Int Bool)
