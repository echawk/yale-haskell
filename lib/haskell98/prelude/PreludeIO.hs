-- I/O functions and definitions (Haskell 98: monadic I/O)
--
-- IO is a newtype over Yale's state-passing representation.  The
-- constructor is erased by the compiler, so the Lisp primitives, which
-- work on the state-passing functions, are unchanged.
--
-- The 1.2 Dialogue functions that do not clash with the Prelude's
-- monadic ones are kept for the tests and the old programs
-- (appendChan, readChan, done, abort, exit, the channel names).  The
-- clashing ones (readFile, writeFile, appendFile, getArgs, ...) are the
-- H98 versions; the rest of the 1.2 system interface is gone.

module PreludeIO(stdin,stdout,stderr,stdecho,
                 IOError(..),Dialogue(..),IO,SystemState,IOResult,FilePath(..),
                 SuccCont(..),StrCont(..),StrListCont(..),FailCont(..),
                 ioError, userError, catch,
                 putChar, putStr, putStrLn, print, getChar, getLine,
                 getContents, interact, readFile, writeFile, appendFile,
                 readIO, readLn,
                 readChan, appendChan,
                 done, exit, abort, prints,
		 thenIO,thenIO_,seqIO,returnIO, doneIO)
   where

import PreludeBltinIO
import IOPrims
import PreludeBltinArray(strict1)
import PreludeCore(Monad(..), Functor(..))
import PreludeText(reads, lex, shows, showString)

{-#Prelude#-}  -- Indicates definitions of compiler prelude symbols

-- These datatypes are used by the monad.

newtype IO a = IO (SystemState -> IOResult a)

data SystemState = SystemState
data IOResult a = IOResult a

unIO :: IO a -> SystemState -> IOResult a
unIO (IO f) = f

-- Operations in the monad

-- This definition is needed to allow proper tail recursion of the Lisp
-- code.  The use of strict1 forces f1 s (since getState is strict) before
-- the call to f2.  The optimizer removed getState and getRes from the
-- generated code.

thenIO :: IO a -> (a -> IO b) -> IO b
thenIO f1 f2 =
  IO (\s -> let g = unIO f1 s
                s' = getState g in
            strict1 s' (unIO (f2 (getRes g)) s'))
{-# thenIO :: Inline #-}

thenIO_ :: IO a -> IO b -> IO b
x `thenIO_` y = x `thenIO` \_ -> y

seqIO :: IO a -> IO b -> IO b
x `seqIO` y = x `thenIO` \_ -> y

-- The returnIO function is implemented directly as a primitive.
doneIO :: IO ()
doneIO = returnIO ()

instance Functor IO where
  fmap f x = x `thenIO` \a -> returnIO (f a)

instance Monad IO where
  m >>= k   = thenIO m k
  m >> k    = thenIO_ m k
  return x  = returnIO x
  fail s    = ioError (userError s)


-- IOErrors.  The Lisp side is src/runtime/io-errors.mumble: every H98
-- library primitive raises these conditions.

data IOError = IOError IOErrorObj

instance Eq IOError where
  IOError a == IOError b  =  primIOErrorMessage a == primIOErrorMessage b

instance  Show IOError  where
  showsPrec _ (IOError e) = showString (primIOErrorMessage e)

ioError               :: IOError -> IO a
ioError (IOError e)   =  primThrowIO e

userError             :: String -> IOError
userError s           =  IOError (primUserError s)

catch                 :: IO a -> (IOError -> IO a) -> IO a
catch m h             =  primCatchIO m (\e -> h (IOError e))


-- Standard I/O, on the handle primitives

type FilePath = String

putChar               :: Char -> IO ()
putChar c             =  primHPutChar primStdout c

putStr                :: String -> IO ()
putStr s              =  primHPutStr primStdout s

putStrLn              :: String -> IO ()
putStrLn s            =  putStr s `thenIO_` putChar '\n'

print                 :: (Show a) => a -> IO ()
print x               =  putStrLn (show x)

getChar               :: IO Char
getChar               =  primHGetChar primStdin

getLine               :: IO String
getLine               =  primHGetLine primStdin

getContents           :: IO String
getContents           =  primHGetContents primStdin

interact              :: (String -> String) -> IO ()
interact f            =  getContents `thenIO` \s -> putStr (f s)

readFile              :: FilePath -> IO String
readFile name         =  primOpenFile name 0 `thenIO` \h ->
                         primHGetContents h

writeFile             :: FilePath -> String -> IO ()
writeFile name s      =  primOpenFile name 1 `thenIO` \h ->
                         primHPutStr h s `thenIO_`
                         primHClose h

appendFile            :: FilePath -> String -> IO ()
appendFile name s     =  primOpenFile name 2 `thenIO` \h ->
                         primHPutStr h s `thenIO_`
                         primHClose h

readIO                :: (Read a) => String -> IO a
readIO s              =  case [x | (x,t) <- reads s, ("","") <- lex t] of
                           [x] -> returnIO x
                           []  -> ioError (userError "Prelude.readIO: no parse")
                           _   -> ioError (userError "Prelude.readIO: ambiguous parse")

readLn                :: (Read a) => IO a
readLn                =  getLine `thenIO` readIO


-- File and channel names (Yale Haskell 1.2 compatibility):

stdin	    =  "stdin"
stdout      =  "stdout"
stderr      =  "stderr"
stdecho     =  "stdecho"


-- Continuation-based I/O (Yale Haskell 1.2 compatibility):

type Dialogue    =  IO ()
type SuccCont    =                Dialogue
type StrCont     =  String     -> Dialogue
type StrListCont =  [String]   -> Dialogue
type FailCont    =  IOError    -> Dialogue

done	      ::                                                Dialogue
readChan      :: String ->           FailCont -> StrCont     -> Dialogue
appendChan    :: String -> String -> FailCont -> SuccCont    -> Dialogue

done = returnIO ()

readChan name fail succ =
 if name == stdin then
    getContents `thenIO` succ
 else
    badChan fail name

appendChan name contents fail succ =
 if name == stdout then
    putStr contents `thenIO_` succ
 else if name == stderr then
    primHPutStr primStderr contents `thenIO_` succ
 else
    badChan fail name

badChan f name = f (userError ("Improper IO Channel: " ++ name))

abort		:: FailCont
abort err	=  done

exit		:: FailCont
exit err	=  appendChan stderr (shows err "\n") abort done

prints          :: (Show a) => a -> String -> Dialogue
prints x s	=  putStr (shows x s)
