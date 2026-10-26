-- Control.Concurrent.Chan (base): an unbounded channel, as base's: a
-- linked list of MVars, with an MVar for each end.  Reading an empty
-- channel waits for a write.
module Control.Concurrent.Chan (
    Chan, newChan, writeChan, readChan, dupChan, getChanContents,
    writeList2Chan
  ) where

import Control.Concurrent.MVar
import Control.Exception (mask_)
import System.IO.Unsafe (unsafeInterleaveIO)

data Chan a = Chan (MVar (Stream a)) (MVar (Stream a))

type Stream a = MVar (ChItem a)

data ChItem a = ChItem a (Stream a)

instance Eq (Chan a) where
  Chan r _ == Chan r' _ = r == r'

newChan :: IO (Chan a)
newChan = do
  hole <- newEmptyMVar
  r <- newMVar hole
  w <- newMVar hole
  return (Chan r w)

writeChan :: Chan a -> a -> IO ()
writeChan (Chan _ w) x = do
  hole <- newEmptyMVar
  mask_ $ do
    old <- takeMVar w
    putMVar old (ChItem x hole)
    putMVar w hole

readChan :: Chan a -> IO a
readChan (Chan r _) = modifyMVar r $ \end -> do
  ChItem x next <- readMVar end
  return (next, x)

dupChan :: Chan a -> IO (Chan a)
dupChan (Chan _ w) = do
  hole <- readMVar w
  r <- newMVar hole
  return (Chan r w)

getChanContents :: Chan a -> IO [a]
getChanContents ch = unsafeInterleaveIO $ do
  x <- readChan ch
  xs <- getChanContents ch
  return (x : xs)

writeList2Chan :: Chan a -> [a] -> IO ()
writeList2Chan ch = mapM_ (writeChan ch)
