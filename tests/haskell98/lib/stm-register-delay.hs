import Control.Concurrent.STM

main :: IO ()
main = do
  v <- registerDelay 20000
  atomically (readTVar v >>= check)
  atomically (readTVar v) >>= print
