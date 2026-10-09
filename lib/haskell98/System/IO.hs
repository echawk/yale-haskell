-- System.IO: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module IO
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.IO (
    IO, FilePath, fixIO,
    Handle, HandlePosn, IOMode(ReadMode, WriteMode, AppendMode, ReadWriteMode),
    BufferMode(NoBuffering, LineBuffering, BlockBuffering),
    SeekMode(AbsoluteSeek, RelativeSeek, SeekFromEnd),
    stdin, stdout, stderr, withFile, openFile, hClose, hFileSize, hIsEOF, isEOF,
    hSetBuffering, hGetBuffering, hFlush, hGetPosn, hSetPosn, hSeek,
    hWaitForInput, hReady, hGetChar, hGetLine, hLookAhead, hGetContents,
    hPutChar, hPutStr, hPutStrLn, hPrint,
    hIsOpen, hIsClosed, hIsReadable, hIsWritable, hIsSeekable,
    interact, putChar, putStr, putStrLn, print, getChar, getLine, getContents,
    readIO, readLn, readFile, writeFile, appendFile,
    hSetFileSize, hTell, hIsTerminalDevice, hSetEcho, hGetEcho, hShow,
    -- base, not the Report
    openTempFile
  ) where

import IO
import IOBase(Handle(..), HandlePosn(..))
import BasePrims
import IOPrims(primHandleName)

-- Run the action with the handle, closing it afterwards (also on error).
withFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r
withFile name mode = bracket (openFile name mode) hClose

-- No IORef in Haskell 98: fixIO ties the knot through a lazy result.
fixIO :: (a -> IO a) -> IO a
fixIO k = let r = k (error "fixIO: value used before it is defined") in r

-- The file's size, truncating or extending it (the handle is flushed).
hSetFileSize :: Handle -> Integer -> IO ()
hSetFileSize h size = do
  hFlush h
  primTruncateFile (handleName h) size

-- The handle's position, as hGetPosn.
hTell :: Handle -> IO Integer
hTell h = do
  HandlePosn _ p <- hGetPosn h
  return p

-- Only the standard handles can be terminals.
hIsTerminalDevice :: Handle -> IO Bool
hIsTerminalDevice h = primIsTerminal (stdDescriptor h)

stdDescriptor :: Handle -> Int
stdDescriptor h | h == stdin  = 0
                | h == stdout = 1
                | h == stderr = 2
                | otherwise   = -1

-- Echoing of input: a terminal's setting; False, and unchangeable, for
-- other handles.
hGetEcho :: Handle -> IO Bool
hGetEcho h = do
  tty <- hIsTerminalDevice h
  if tty then primGetEcho else return False

hSetEcho :: Handle -> Bool -> IO ()
hSetEcho h on = do
  tty <- hIsTerminalDevice h
  if tty then primSetEcho on else return ()

hShow :: Handle -> IO String
hShow h = return (show h)

handleName :: Handle -> String
handleName (Handle h) = primHandleName h

-- A new file in the directory, named from the template (prefix.ext
-- becomes prefixNNN.ext), opened for reading and writing.
openTempFile :: FilePath -> String -> IO (FilePath, Handle)
openTempFile dir template = do
  let (prefix, suffix) = splitTemplate template
  path <- primCreateTempFile dir prefix suffix
  h <- openFile path ReadWriteMode
  return (path, h)

splitTemplate :: String -> (String, String)
splitTemplate t = case break (== '.') (reverse t) of
                    (rext, '.':rbase) -> (reverse rbase, '.' : reverse rext)
                    _                 -> (t, "")
