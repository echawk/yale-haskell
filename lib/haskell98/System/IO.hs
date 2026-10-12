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
    openTempFile, openBinaryFile, withBinaryFile, hSetBinaryMode,
    TextEncoding, utf8, utf8_bom, latin1, char8, utf16, utf32, mkTextEncoding,
    localeEncoding, hSetEncoding, hGetEncoding,
    Newline(LF, CRLF), NewlineMode(NewlineMode, inputNL, outputNL),
    nativeNewline, noNewlineTranslation, universalNewlineMode,
    nativeNewlineMode, hSetNewlineMode, hGetContents', readFile'
  ) where

import IO
import IOBase(Handle(..), HandlePosn(..))
import BasePrims
import IOPrims(primHandleName, primOpenFile, primHSetBinaryMode)
import Data.IORef (newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafeInterleaveIO)

-- Run the action with the handle, closing it afterwards (also on error).
withFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r
withFile name mode = bracket (openFile name mode) hClose

-- The result is read lazily from a reference filled in afterwards.
fixIO :: (a -> IO a) -> IO a
fixIO k = do
  ref <- newIORef (error "fixIO: value used before it is defined")
  ans <- unsafeInterleaveIO (readIORef ref)
  result <- k ans
  writeIORef ref result
  return result

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

-- base: binary mode, text encodings and newline modes.  Text is UTF-8;
-- binary mode (openBinaryFile, hSetBinaryMode on stdin) reads and
-- writes one Char per byte.  Encodings and newline modes are recorded
-- nowhere: text is always UTF-8 with \n.
openBinaryFile :: FilePath -> IOMode -> IO Handle
openBinaryFile name mode = primOpenFile name (8 + n) >>= return . Handle
  where n = case mode of { ReadMode -> 0; WriteMode -> 1; AppendMode -> 2; ReadWriteMode -> 3 }

withBinaryFile :: FilePath -> IOMode -> (Handle -> IO r) -> IO r
withBinaryFile name mode = bracket (openBinaryFile name mode) hClose

hSetBinaryMode :: Handle -> Bool -> IO ()
hSetBinaryMode (Handle h) b = primHSetBinaryMode h b

newtype TextEncoding = TextEncoding String
instance Show TextEncoding where show (TextEncoding n) = n

utf8, utf8_bom, latin1, char8, utf16, utf32, localeEncoding :: TextEncoding
utf8 = TextEncoding "UTF-8"
utf8_bom = TextEncoding "UTF-8BOM"
latin1 = TextEncoding "ISO-8859-1"
char8 = TextEncoding "char8"
utf16 = TextEncoding "UTF-16"
utf32 = TextEncoding "UTF-32"
localeEncoding = utf8

mkTextEncoding :: String -> IO TextEncoding
mkTextEncoding n = return (TextEncoding n)

hSetEncoding :: Handle -> TextEncoding -> IO ()
hSetEncoding _ _ = return ()

hGetEncoding :: Handle -> IO (Maybe TextEncoding)
hGetEncoding _ = return (Just utf8)

data Newline = LF | CRLF deriving (Eq, Ord, Show, Read)
data NewlineMode = NewlineMode { inputNL :: Newline, outputNL :: Newline }
  deriving (Eq, Ord, Show, Read)

nativeNewline :: Newline
nativeNewline = LF

noNewlineTranslation, universalNewlineMode, nativeNewlineMode :: NewlineMode
noNewlineTranslation = NewlineMode LF LF
universalNewlineMode = NewlineMode CRLF LF
nativeNewlineMode = NewlineMode LF LF

hSetNewlineMode :: Handle -> NewlineMode -> IO ()
hSetNewlineMode _ _ = return ()

-- The whole contents, read at once.
hGetContents' :: Handle -> IO String
hGetContents' h = do
  s <- hGetContents h
  length s `seq` return s

readFile' :: FilePath -> IO String
readFile' f = do
  s <- readFile f
  length s `seq` return s
