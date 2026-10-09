-- System.IO: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module IO
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.IO (
    fixIO,
    Handle, HandlePosn, IOMode(ReadMode, WriteMode, AppendMode, ReadWriteMode),
    BufferMode(NoBuffering, LineBuffering, BlockBuffering),
    SeekMode(AbsoluteSeek, RelativeSeek, SeekFromEnd),
    stdin, stdout, stderr, withFile, openFile, hClose, hFileSize, hIsEOF, isEOF,
    hSetBuffering, hGetBuffering, hFlush, hGetPosn, hSetPosn, hSeek,
    hWaitForInput, hReady, hGetChar, hGetLine, hLookAhead, hGetContents,
    hPutChar, hPutStr, hPutStrLn, hPrint,
    hIsOpen, hIsClosed, hIsReadable, hIsWritable, hIsSeekable,
    interact, putChar, putStr, putStrLn, print, getChar, getLine, getContents,
    readIO, readLn, readFile, writeFile, appendFile
  ) where

import IO

-- Run the action with the handle, closing it afterwards (also on error).
withFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r
withFile name mode = bracket (openFile name mode) hClose

-- No IORef in Haskell 98: fixIO ties the knot through a lazy result.
fixIO :: (a -> IO a) -> IO a
fixIO k = let r = k (error "fixIO: value used before it is defined") in r
