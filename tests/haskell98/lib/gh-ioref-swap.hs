import GHC.IORef

main :: IO ()
main = do
  r <- newIORef (1 :: Int)
  old <- atomicSwapIORef r 5
  (o, n) <- atomicModifyIORef'_ r (* 3)
  v <- readIORef r
  print (old, o, n, v)
