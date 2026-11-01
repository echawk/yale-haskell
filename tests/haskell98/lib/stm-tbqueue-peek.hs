import Control.Concurrent.STM
main :: IO ()
main = do
  q <- newTBQueueIO 3
  atomically (writeTBQueue q (1 :: Int) >> writeTBQueue q 2)
  atomically (peekTBQueue q) >>= print
  atomically (unGetTBQueue q 0)
  atomically (lengthTBQueue q) >>= print
  atomically (tryPeekTBQueue q) >>= print
  atomically (flushTBQueue q) >>= print
