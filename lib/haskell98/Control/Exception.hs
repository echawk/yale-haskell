-- Control.Exception (base, a subset), for Yale Haskell's Haskell 98
-- dialect.  An exception is a Lisp condition (src/base/base-runtime.lisp):
-- an IOError, an ErrorCall (error, a failed pattern match) or an
-- ArithException (division by zero).  catch and try catch all three,
-- including runtime errors raised by pure code evaluated inside the
-- action.  The SomeException constructor holds the host's condition,
-- which Show shows.  A program's own exception types (instance Exception
-- T, with the default methods) are thrown as a condition holding the
-- value as a Dynamic (Typeable is built in), so catch, try and catches
-- find them by type, as in base.  ExitCode is not an exception (exitWith
-- is not caught).
module Control.Exception (
    SomeException(SomeException), IOException, ErrorCall(ErrorCall), ArithException(..),
    AsyncException(..), AssertionFailed(AssertionFailed),
    Exception(toException, fromException, displayException),
    Handler(Handler), catches, catchJust, handleJust, tryJust,
    catch, handle, try, evaluate, throw, throwIO,
    bracket, bracket_, bracketOnError, finally, onException,
    mask, mask_, uninterruptibleMask, uninterruptibleMask_, assert
  ) where

import Prelude hiding (catch)
import PreludeIO (IOError(..))
import BasePrims
import Data.Typeable (Typeable)
import Data.Dynamic (toDyn, fromDynamic)

data SomeException = SomeException Exc

type IOException = IOError

data ErrorCall = ErrorCall String
  deriving (Eq, Ord)

data ArithException = Overflow | Underflow | LossOfPrecision | DivideByZero
                    | Denormal | RatioZeroDenominator
  deriving (Eq, Ord)

-- the constructor's number, as base-runtime.lisp's haskell-arith-error has it
arithCode :: ArithException -> Int
arithCode e = case e of
  Overflow -> 0; Underflow -> 1; LossOfPrecision -> 2; DivideByZero -> 3
  Denormal -> 4; RatioZeroDenominator -> 5

arithFromCode :: Int -> ArithException
arithFromCode n = [Overflow, Underflow, LossOfPrecision, DivideByZero,
                   Denormal, RatioZeroDenominator] !! n

instance Show SomeException where
  showsPrec _ (SomeException e) = showString (primExcMessage e)

-- The exception inside a SomeException: matching (SomeException e) and
-- showing e works as with base's existential SomeException.
instance Show Exc where
  showsPrec _ e = showString (primExcMessage e)

instance Show ErrorCall where
  showsPrec _ (ErrorCall m) = showString m

instance Show ArithException where
  showsPrec _ e = showString (primExcMessage (primMakeArithError (arithCode e)))

class (Typeable e, Show e) => Exception e where
  toException      :: e -> SomeException
  fromException    :: SomeException -> Maybe e
  displayException :: e -> String

  toException e = SomeException (primMakeUserExc (show e) (toDyn e))
  fromException (SomeException x)
    | primExcKind x == 3 = fromDynamic (primExcValue x)
    | otherwise          = Nothing
  displayException = show

instance Exception SomeException where
  toException = id
  fromException = Just

instance Exception IOError where
  toException (IOError obj) = SomeException (primObjToExc obj)
  fromException (SomeException e)
    | primExcKind e == 0 = Just (IOError (primExcToObj e))
    | otherwise          = Nothing

instance Exception ErrorCall where
  toException (ErrorCall m) = SomeException (primMakeErrorCall m)
  fromException (SomeException e)
    | primExcKind e == 1 = Just (ErrorCall (primExcMessage e))
    | otherwise          = Nothing

instance Exception ArithException where
  toException a = SomeException (primMakeArithError (arithCode a))
  fromException (SomeException e)
    | primExcKind e == 2 = Just (arithFromCode (primArithCode e))
    | otherwise          = Nothing

catch :: Exception e => IO a -> (e -> IO a) -> IO a
catch action handler =
  primCatchAny action (\e -> case fromException (SomeException e) of
                               Just x  -> handler x
                               Nothing -> primThrowExc e)

-- A handler for one exception type, for catches.
data Handler a = forall e . Exception e => Handler (e -> IO a)

-- The first handler whose type the exception has.
catches :: IO a -> [Handler a] -> IO a
catches action handlers = action `catch` \e -> pick handlers e
  where pick [] e = throwIO (e :: SomeException)
        pick (Handler h : hs) e = case fromException e of
                                    Just x  -> h x
                                    Nothing -> pick hs e

catchJust :: Exception e => (e -> Maybe b) -> IO a -> (b -> IO a) -> IO a
catchJust p a handler = a `catch` \e -> case p e of
                                          Nothing -> throwIO e
                                          Just b  -> handler b

handleJust :: Exception e => (e -> Maybe b) -> (b -> IO a) -> IO a -> IO a
handleJust p handler a = catchJust p a handler

tryJust :: Exception e => (e -> Maybe b) -> IO a -> IO (Either b a)
tryJust p a = catchJust p (fmap Right a) (return . Left)

-- Asynchronous exceptions are never raised (one thread), but programs
-- name and catch them.
data AsyncException = StackOverflow | HeapOverflow | ThreadKilled | UserInterrupt
  deriving (Eq, Ord)

instance Show AsyncException where
  showsPrec _ StackOverflow = showString "stack overflow"
  showsPrec _ HeapOverflow = showString "heap overflow"
  showsPrec _ ThreadKilled = showString "thread killed"
  showsPrec _ UserInterrupt = showString "user interrupt"

instance Exception AsyncException

newtype AssertionFailed = AssertionFailed String

instance Show AssertionFailed where
  showsPrec _ (AssertionFailed s) = showString s

instance Exception AssertionFailed

handle :: Exception e => (e -> IO a) -> IO a -> IO a
handle = flip catch

try :: Exception e => IO a -> IO (Either e a)
try a = catch (a >>= \v -> return (Right v)) (\e -> return (Left e))

evaluate :: a -> IO a
evaluate = primEvaluate

throw :: Exception e => e -> a
throw e = case toException e of SomeException x -> primThrowExc x

throwIO :: Exception e => e -> IO a
throwIO e = return () >>= \_ -> throw e

onException :: IO a -> IO b -> IO a
onException io what =
  io `catch` \e -> what >> throwIO (e :: SomeException)

bracket :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
bracket before after thing = do
  a <- before
  r <- thing a `onException` after a
  _ <- after a
  return r

bracket_ :: IO a -> IO b -> IO c -> IO c
bracket_ before after thing = bracket before (const after) (const thing)

bracketOnError :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
bracketOnError before after thing = do
  a <- before
  thing a `onException` after a

finally :: IO a -> IO b -> IO a
finally a sequel = do
  r <- a `onException` sequel
  _ <- sequel
  return r

-- no asynchronous exceptions: masking does nothing
mask :: ((forall c . IO c -> IO c) -> IO b) -> IO b
mask f = f id

uninterruptibleMask :: ((forall c . IO c -> IO c) -> IO b) -> IO b
uninterruptibleMask f = f id

mask_ :: IO a -> IO a
mask_ = id

uninterruptibleMask_ :: IO a -> IO a
uninterruptibleMask_ = id

assert :: Bool -> a -> a
assert True x  = x
assert False _ = error "Assertion failed"
