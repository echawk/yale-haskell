-- mkWeakThreadId gives a Weak ThreadId (base's type; GHC's Panic).
import Control.Concurrent
import System.Mem.Weak
main = do
  t <- myThreadId
  w <- mkWeakThreadId t
  r <- deRefWeak w
  print (fmap (== t) r)
