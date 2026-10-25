-- System.Mem.Weak: a live key's weak pointer gives its value; finalize
-- runs the finalizer once.  Data.IORef's mkWeakIORef (network's).
import System.Mem.Weak
import Data.IORef
main :: IO ()
main = do
  r <- newIORef (5 :: Int)
  w <- mkWeakIORef r (putStrLn "finalized")
  Just r' <- deRefWeak w
  readIORef r' >>= print
  finalize w
  finalize w
  w2 <- mkWeakPtr "key" Nothing
  deRefWeak w2 >>= print
  readIORef r >>= print
