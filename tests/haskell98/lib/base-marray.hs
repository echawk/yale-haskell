-- array: Data.Array.ST, Data.Array.IO, Data.Array.Unboxed, Data.Array.Base.
import Control.Monad.ST
import Data.Array.ST
import Data.Array.IO
import Data.Array.Unboxed
import Data.Array.Base (unsafeRead, unsafeWrite)
import Data.STRef

sieve :: Int -> UArray Int Bool
sieve n = runSTUArray (do
  a <- newArray (2, n) True
  let loop i | i * i > n = return ()
             | otherwise = do
                 p <- readArray a i
                 if p then mapM_ (\j -> writeArray a j False) [i * i, i * i + i .. n] else return ()
                 loop (i + 1)
  loop 2
  return a)

sumST :: [Int] -> Int
sumST xs = runST (do
  arr <- newListArray (0, length xs - 1) xs :: ST s (STUArray s Int Int)
  r <- newSTRef 0
  mapM_ (\i -> unsafeRead arr i >>= \x -> modifySTRef r (+ x)) [0 .. length xs - 1]
  readSTRef r)

main :: IO ()
main = do
  print [i | (i, True) <- assocs (sieve 50)]
  print (sumST [1 .. 100])
  io <- newArray ((0, 0), (2, 2)) 0 :: IO (IOArray (Int, Int) Int)
  mapM_ (\(i, j) -> writeArray io (i, j) (i * 3 + j)) [(i, j) | i <- [0 .. 2], j <- [0 .. 2]]
  modifyArray io (1, 1) (* 100)
  getElems io >>= print
  frozen <- freeze io :: IO (Array (Int, Int) Int)
  print (frozen ! (2, 1), bounds frozen)
  getBounds io >>= print
