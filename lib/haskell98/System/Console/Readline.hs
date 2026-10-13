-- System.Console.Readline (the readline package): a prompt and a line
-- from standard input, without line editing (as GNU readline behaves
-- when its input is not a terminal); the history is kept but unused.
module System.Console.Readline (readline, addHistory, clearHistory) where

import System.IO
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)

history :: IORef [String]
history = unsafePerformIO (newIORef [])
{-# NOINLINE history #-}

readline :: String -> IO (Maybe String)
readline prompt = do
  putStr prompt
  hFlush stdout
  eof <- isEOF
  if eof then return Nothing else fmap Just getLine

addHistory :: String -> IO ()
addHistory l = modifyIORef history (l :)

clearHistory :: IO ()
clearHistory = writeIORef history []
