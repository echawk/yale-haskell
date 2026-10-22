module Main (main) where
import Control.Monad.STM
import Control.Concurrent.STM.TChan
import Control.Concurrent.STM.TVar
main :: IO ()
main = do
  c <- newTChanIO
  v <- newTVarIO (1 :: Int)
  atomically (writeTChan c "x" >> modifyTVar v (+ 1))
  x <- atomically (readTChan c)
  n <- readTVarIO v
  print (x, n)
