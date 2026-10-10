-- Data.IORef, Control.Monad.ST, Data.STRef, System.IO.Unsafe (base).
import Data.IORef
import Control.Monad.ST
import Data.STRef
import System.IO.Unsafe

sumST :: [Int] -> Int
sumST xs = runST (do
  ref <- newSTRef 0
  mapM_ (\x -> modifySTRef' ref (+ x)) xs
  readSTRef ref)

counter :: IORef Int
counter = unsafePerformIO (newIORef 100)

main :: IO ()
main = do
  r <- newIORef (0 :: Int)
  mapM_ (\i -> modifyIORef r (+ i)) [1 .. 10]
  readIORef r >>= print
  v <- atomicModifyIORef r (\x -> (x * 2, x + 1))
  print v
  readIORef r >>= print
  lazy <- newIORef (undefined :: Int)
  writeIORef lazy 7
  readIORef lazy >>= print
  r2 <- newIORef (0 :: Int)
  print (r == r, r == r2)
  print (sumST [1 .. 100])
  modifyIORef counter (+ 1)
  readIORef counter >>= print
  xs <- unsafeInterleaveIO (putStrLn "forced" >> return [1, 2, 3 :: Int])
  putStrLn "before"
  print (sum xs)
