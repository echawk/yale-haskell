-- IO.hs -- the Haskell 98 IO library (standalone version)
--
-- Interface as in the Haskell 98 Library Report, chapter 11, built on
-- Lisp streams (src/runtime/handle-prims.mumble) and a Lisp condition
-- model of IOError (src/runtime/io-errors.mumble).
--
-- The Prelude is still Haskell 1.2, so this module stands apart from
-- it until the Prelude's I/O becomes H98:
--   * IOError, ioError, userError and catch are defined here, over the
--     runtime's IOError conditions, which every H98 library primitive
--     raises.  The Prelude's 1.2 IOError (a data type used by the
--     Dialogue failure continuations) is a different type and is
--     hidden.  The H98 Prelude should take these definitions over and
--     this module re-export them.
--   * The Prelude's stdin/stdout/stderr are channel-name Strings, so
--     they are hidden here; a program importing IO must hide them too
--     (import Prelude hiding (IOError, stdin, stdout, stderr)).
--   * The rest of what H98's IO re-exports from the Prelude (putStr,
--     getLine, readFile, ...) is not available in monadic form yet.
--   * The H98 single-writer/multiple-reader file locking is not
--     implemented, so isAlreadyInUseError never arises from openFile.
--   * hWaitForInput ignores its timeout except for the sign: a
--     negative one waits, any other value only checks for input now.

module IO (
    Handle, HandlePosn,
    IOMode(ReadMode,WriteMode,AppendMode,ReadWriteMode),
    BufferMode(NoBuffering,LineBuffering,BlockBuffering),
    SeekMode(AbsoluteSeek,RelativeSeek,SeekFromEnd),
    stdin, stdout, stderr,
    openFile, hClose, hFileSize, hIsEOF, isEOF,
    hSetBuffering, hGetBuffering, hFlush,
    hGetPosn, hSetPosn, hSeek,
    hWaitForInput, hReady, hGetChar, hGetLine, hLookAhead,
    hGetContents, hPutChar, hPutStr, hPutStrLn, hPrint,
    hIsOpen, hIsClosed, hIsReadable, hIsWritable, hIsSeekable,
    isAlreadyExistsError, isDoesNotExistError, isAlreadyInUseError,
    isFullError, isEOFError,
    isIllegalOperation, isPermissionError, isUserError,
    ioeGetErrorString, ioeGetHandle, ioeGetFileName,
    bracket, bracket_, try
    ) where

import PreludeIO(IOError(..), thenIO, thenIO_, returnIO, catch)
import IOPrims
import IOBase(Handle(..), HandlePosn(..))

-- IOErrors.  The wrappers exist because Yale requires instances to be
-- declared in the module that defines the type.

-- The kind numbers are those of *io-error-kinds* in io-errors.mumble.
errorKind             :: IOError -> Int
errorKind (IOError e) =  primIOErrorKind e

isAlreadyExistsError, isDoesNotExistError, isAlreadyInUseError,
  isFullError, isEOFError, isIllegalOperation, isPermissionError,
  isUserError         :: IOError -> Bool
isAlreadyExistsError e = errorKind e == 1
isDoesNotExistError e  = errorKind e == 2
isAlreadyInUseError e  = errorKind e == 3
isFullError e          = errorKind e == 4
isEOFError e           = errorKind e == 5
isIllegalOperation e   = errorKind e == 6
isPermissionError e    = errorKind e == 7
isUserError e          = errorKind e == 8

ioeGetErrorString     :: IOError -> String
ioeGetErrorString (IOError e) = primIOErrorString e

ioeGetFileName        :: IOError -> Maybe FilePath
ioeGetFileName (IOError e) | primIOErrorHasFile e = Just (primIOErrorFile e)
                           | otherwise            = Nothing

ioeGetHandle          :: IOError -> Maybe Handle
ioeGetHandle (IOError e) | primIOErrorHasHandle e
                                   = Just (Handle (primIOErrorHandle e))
                         | otherwise = Nothing

try                   :: IO a -> IO (Either IOError a)
try a                 =  catch (a `thenIO` \v -> returnIO (Right v))
                               (\e -> returnIO (Left e))

bracket               :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
bracket before after thing =
  before `thenIO` \a ->
  catch (thing a) (\e -> after a `thenIO_` ioError e) `thenIO` \r ->
  after a `thenIO_`
  returnIO r

bracket_              :: IO a -> (a -> IO b) -> IO c -> IO c
bracket_ before after thing =
  bracket before after (\_ -> thing)

data IOMode      =  ReadMode | WriteMode | AppendMode | ReadWriteMode
                    deriving (Eq, Ord, Ix, Enum, Show, Read)
data BufferMode  =  NoBuffering | LineBuffering
                 |  BlockBuffering (Maybe Int)
                    deriving (Eq, Ord, Show, Read)
data SeekMode    =  AbsoluteSeek | RelativeSeek | SeekFromEnd
                    deriving (Eq, Ord, Ix, Enum, Show, Read)

stdin, stdout, stderr :: Handle
stdin                 =  Handle primStdin
stdout                =  Handle primStdout
stderr                =  Handle primStderr

openFile              :: String -> IOMode -> IO Handle
openFile name mode    =  primOpenFile name (modeNumber mode) `thenIO` \h ->
                         returnIO (Handle h)
  where modeNumber ReadMode      = 0
        modeNumber WriteMode     = 1
        modeNumber AppendMode    = 2
        modeNumber ReadWriteMode = 3

hClose                :: Handle -> IO ()
hClose (Handle h)     =  primHClose h

hFileSize             :: Handle -> IO Integer
hFileSize (Handle h)  =  primHFileSize h

hIsEOF                :: Handle -> IO Bool
hIsEOF (Handle h)     =  primHIsEOF h

isEOF                 :: IO Bool
isEOF                 =  hIsEOF stdin

hSetBuffering         :: Handle -> BufferMode -> IO ()
hSetBuffering (Handle h) NoBuffering        = primHSetBuffering h 0 0
hSetBuffering (Handle h) LineBuffering      = primHSetBuffering h 1 0
hSetBuffering (Handle h) (BlockBuffering Nothing)  = primHSetBuffering h 2 0
hSetBuffering (Handle h) (BlockBuffering (Just n)) = primHSetBuffering h 2 n

hGetBuffering         :: Handle -> IO BufferMode
hGetBuffering (Handle h) =
  primHGetBuffering h `thenIO` \m ->
  primHGetBlockSize h `thenIO` \n ->
  returnIO (case m of
              0 -> NoBuffering
              1 -> LineBuffering
              _ -> BlockBuffering (if n == 0 then Nothing else Just n))

hFlush                :: Handle -> IO ()
hFlush (Handle h)     =  primHFlush h

hGetPosn              :: Handle -> IO HandlePosn
hGetPosn (Handle h)   =  primHGetPosn h `thenIO` \p ->
                         returnIO (HandlePosn (Handle h) p)

hSetPosn              :: HandlePosn -> IO ()
hSetPosn (HandlePosn (Handle h) p) = primHSeek h 0 p

hSeek                 :: Handle -> SeekMode -> Integer -> IO ()
hSeek (Handle h) AbsoluteSeek n = primHSeek h 0 n
hSeek (Handle h) RelativeSeek n = primHSeek h 1 n
hSeek (Handle h) SeekFromEnd n  = primHSeek h 2 n

hWaitForInput         :: Handle -> Int -> IO Bool
hWaitForInput (Handle h) t = primHWaitForInput h t

hReady                :: Handle -> IO Bool
hReady h              =  hWaitForInput h 0

hGetChar              :: Handle -> IO Char
hGetChar (Handle h)   =  primHGetChar h

hGetLine              :: Handle -> IO String
hGetLine (Handle h)   =  primHGetLine h

hLookAhead            :: Handle -> IO Char
hLookAhead (Handle h) =  primHLookAhead h

hGetContents          :: Handle -> IO String
hGetContents (Handle h) = primHGetContents h

hPutChar              :: Handle -> Char -> IO ()
hPutChar (Handle h) c =  primHPutChar h c

hPutStr               :: Handle -> String -> IO ()
hPutStr (Handle h) s  =  primHPutStr h s

hPutStrLn             :: Handle -> String -> IO ()
hPutStrLn h s         =  hPutStr h s `thenIO_` hPutChar h '\n'

hPrint                :: Show a => Handle -> a -> IO ()
hPrint h x            =  hPutStrLn h (show x)

hIsOpen, hIsClosed, hIsReadable, hIsWritable, hIsSeekable
                      :: Handle -> IO Bool
hIsOpen (Handle h)    =  primHIsOpen h
hIsClosed (Handle h)  =  primHIsClosed h
hIsReadable (Handle h) = primHIsReadable h
hIsWritable (Handle h) = primHIsWritable h
hIsSeekable (Handle h) = primHIsSeekable h
