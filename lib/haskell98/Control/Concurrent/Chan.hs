-- Control.Concurrent.Chan (base), single-threaded: an unbounded queue.
-- Reading an empty channel fails (no other thread can write to it).
module Control.Concurrent.Chan (
    Chan, newChan, writeChan, readChan, dupChan, getChanContents,
    writeList2Chan
  ) where

import Data.IORef

-- front, and back reversed
newtype Chan a = Chan (IORef ([a], [a]))

newChan :: IO (Chan a)
newChan = fmap Chan (newIORef ([], []))

writeChan :: Chan a -> a -> IO ()
writeChan (Chan r) x = modifyIORef r (\(f, b) -> (f, x : b))

readChan :: Chan a -> IO a
readChan (Chan r) = do
  q <- readIORef r
  case q of
    (x : f, b) -> writeIORef r (f, b) >> return x
    ([], []) -> ioError (userError "thread blocked indefinitely in an MVar operation")
    ([], b) -> case reverse b of
                 (x : f) -> writeIORef r (f, []) >> return x
                 [] -> error "readChan"

dupChan :: Chan a -> IO (Chan a)
dupChan (Chan r) = do { q <- readIORef r; fmap Chan (newIORef q) }

-- What has been written so far.
getChanContents :: Chan a -> IO [a]
getChanContents (Chan r) = do
  (f, b) <- readIORef r
  writeIORef r ([], [])
  return (f ++ reverse b)

writeList2Chan :: Chan a -> [a] -> IO ()
writeList2Chan c = mapM_ (writeChan c)
