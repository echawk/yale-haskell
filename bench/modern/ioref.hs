-- Data.IORef: a counter and an accumulator updated 5 million times
-- with modifyIORef', plus forM_ over a range.
import Data.IORef
import Control.Monad

main :: IO ()
main = do
  r <- newIORef (0 :: Int)
  acc <- newIORef (0 :: Int)
  forM_ [1 .. 5000000] $ \i -> do
    modifyIORef' r (+ 1)
    when (i `mod` 3 == 0) $ modifyIORef' acc (+ i)
  readIORef r >>= print
  readIORef acc >>= print
