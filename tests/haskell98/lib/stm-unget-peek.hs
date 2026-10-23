module Main where
import Control.Concurrent.STM
main :: IO ()
main = do
  c <- newTChanIO
  atomically $ do { writeTChan c (1 :: Int); writeTChan c 2; unGetTChan c 0 }
  xs <- atomically $ do { a <- readTChan c; p <- tryPeekTChan c; b <- readTChan c; d <- tryReadTChan c; e <- tryReadTChan c; return (a, p, b, d, e) }
  print xs
