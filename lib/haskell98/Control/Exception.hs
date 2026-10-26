{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
-- Control.Exception (base, a subset), for Yale Haskell's Haskell 98
-- dialect.  An exception is a Lisp condition (src/base/base-runtime.lisp):
-- an IOError, an ErrorCall (error, a failed pattern match) or an
-- ArithException (division by zero).  catch and try catch all three,
-- including runtime errors raised by pure code evaluated inside the
-- action.  The SomeException constructor holds the host's condition,
-- which Show shows.  A program's own exception types (instance Exception
-- T, with the default methods) are thrown as a condition holding the
-- value as a Dynamic (Typeable is built in), so catch, try and catches
-- find them by type, as in base.  ExitCode is an Exception, for handlers
-- that rethrow it (Agda's main), but exitWith is not caught.
module Control.Exception (
    SomeException(SomeException), IOException, ErrorCall(ErrorCall),
    pattern ErrorCallWithLocation, ArithException(..),
    PatternMatchFail(..), RecSelError(..), RecConError(..), RecUpdError(..),
    NoMethodError(..), TypeError(..),
    AsyncException(..), AssertionFailed(AssertionFailed),
    SomeAsyncException(SomeAsyncException), asyncExceptionToException,
    asyncExceptionFromException, BlockedIndefinitelyOnMVar(..),
    BlockedIndefinitelyOnSTM(..), Deadlock(..), NonTermination(..),
    NestedAtomically(..), interruptible,
    Exception(toException, fromException, displayException),
    Handler(Handler), catches, catchJust, handleJust, tryJust,
    catch, handle, try, evaluate, throw, throwIO,
    bracket, bracket_, bracketOnError, finally, onException,
    mask, mask_, uninterruptibleMask, uninterruptibleMask_, assert, throwTo,
    MaskingState(..), getMaskingState, allowInterrupt, mapException, ioError
  ) where

import Prelude hiding (catch)
import PreludeIO (IOError(..))
import BasePrims
import Data.Typeable (Typeable)
import Data.Dynamic (toDyn, fromDynamic)
import System.Exit (ExitCode)
import ConcurrentBase (ThreadId(..), withMaskState)
import ConcurrentPrims (primThrowTo, primGetMask)
import System.IO.Unsafe (unsafePerformIO)

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

-- Asynchronous exceptions: throwTo's (killThread's ThreadKilled).
data AsyncException = StackOverflow | HeapOverflow | ThreadKilled | UserInterrupt
  deriving (Eq, Ord)

instance Show AsyncException where
  showsPrec _ StackOverflow = showString "stack overflow"
  showsPrec _ HeapOverflow = showString "heap overflow"
  showsPrec _ ThreadKilled = showString "thread killed"
  showsPrec _ UserInterrupt = showString "user interrupt"

instance Exception AsyncException

-- The class of asynchronous exceptions, as base's: an exception type
-- that is one has toException = asyncExceptionToException and
-- fromException = asyncExceptionFromException.
data SomeAsyncException = forall e . Exception e => SomeAsyncException e

instance Show SomeAsyncException where
  showsPrec p (SomeAsyncException e) = showsPrec p e

instance Exception SomeAsyncException

asyncExceptionToException :: Exception e => e -> SomeException
asyncExceptionToException = toException . SomeAsyncException

asyncExceptionFromException :: Exception e => SomeException -> Maybe e
asyncExceptionFromException x = case fromException x of
  Just (SomeAsyncException a) -> fromDynamic (toDyn a)
  Nothing -> Nothing

-- Raised by GHC's runtime when a thread can never be woken; here a
-- blocking operation that cannot proceed fails with them.
data BlockedIndefinitelyOnMVar = BlockedIndefinitelyOnMVar

instance Show BlockedIndefinitelyOnMVar where
  showsPrec _ _ = showString "thread blocked indefinitely in an MVar operation"

instance Exception BlockedIndefinitelyOnMVar

data BlockedIndefinitelyOnSTM = BlockedIndefinitelyOnSTM

instance Show BlockedIndefinitelyOnSTM where
  showsPrec _ _ = showString "thread blocked indefinitely in an STM transaction"

instance Exception BlockedIndefinitelyOnSTM

data Deadlock = Deadlock

instance Show Deadlock where
  showsPrec _ _ = showString "<<deadlock>>"

instance Exception Deadlock

-- base's ErrorCall with a location; here the location is empty
pattern ErrorCallWithLocation :: String -> String -> ErrorCall
pattern ErrorCallWithLocation err loc <- (errorCallParts -> (err, loc))
  where ErrorCallWithLocation err _ = ErrorCall err

errorCallParts :: ErrorCall -> (String, String)
errorCallParts (ErrorCall m) = (m, "")

-- The exceptions base's runtime raises for a failed match, a missing
-- record field or method, a deferred type error: here they are raised
-- only by throw (the runtime's own are ErrorCalls), and are for
-- handlers and instances that name them (cmdargs').
newtype PatternMatchFail = PatternMatchFail String
newtype RecSelError = RecSelError String
newtype RecConError = RecConError String
newtype RecUpdError = RecUpdError String
newtype NoMethodError = NoMethodError String
newtype TypeError = TypeError String

instance Show PatternMatchFail where showsPrec _ (PatternMatchFail m) = showString m
instance Show RecSelError where showsPrec _ (RecSelError m) = showString m
instance Show RecConError where showsPrec _ (RecConError m) = showString m
instance Show RecUpdError where showsPrec _ (RecUpdError m) = showString m
instance Show NoMethodError where showsPrec _ (NoMethodError m) = showString m
instance Show TypeError where showsPrec _ (TypeError m) = showString m

instance Exception PatternMatchFail
instance Exception RecSelError
instance Exception RecConError
instance Exception RecUpdError
instance Exception NoMethodError
instance Exception TypeError

data NonTermination = NonTermination

instance Show NonTermination where
  showsPrec _ _ = showString "<<loop>>"

instance Exception NonTermination

data NestedAtomically = NestedAtomically

instance Show NestedAtomically where
  showsPrec _ _ = showString "Control.Concurrent.STM.atomically was nested"

instance Exception NestedAtomically

-- Asynchronous exceptions (throwTo, killThread): masking state is the
-- runtime's, per thread (src/base/concurrent-runtime.lisp)
data MaskingState = Unmasked | MaskedInterruptible | MaskedUninterruptible
  deriving (Eq, Ord, Show)

getMaskingState :: IO MaskingState
getMaskingState = do
  m <- primGetMask
  return (case m of { 0 -> Unmasked; 1 -> MaskedInterruptible; _ -> MaskedUninterruptible })

interruptible :: IO a -> IO a
interruptible act = do
  m <- primGetMask
  if m == 1 then withMaskState 0 act else act

allowInterrupt :: IO ()
allowInterrupt = interruptible (return ())

-- the exception, raised in the thread (at once in this one); waits for
-- nothing
throwTo :: Exception e => ThreadId -> e -> IO ()
throwTo (ThreadId n) e = case toException e of SomeException x -> primThrowTo n x

mapException :: (Exception e1, Exception e2) => (e1 -> e2) -> a -> a
mapException f v = unsafePerformIO (catch (evaluate v) (\ x -> throwIO (f x)))

newtype AssertionFailed = AssertionFailed String

instance Show AssertionFailed where
  showsPrec _ (AssertionFailed s) = showString s

instance Exception AssertionFailed

-- (exitWith exits at once: only a thrown ExitCode is caught as one)
instance Exception ExitCode

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
bracket before after thing = mask $ \restore -> do
  a <- before
  r <- restore (thing a) `onException` after a
  _ <- after a
  return r

bracket_ :: IO a -> IO b -> IO c -> IO c
bracket_ before after thing = bracket before (const after) (const thing)

bracketOnError :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
bracketOnError before after thing = mask $ \restore -> do
  a <- before
  restore (thing a) `onException` after a

finally :: IO a -> IO b -> IO a
finally a sequel = mask $ \restore -> do
  r <- restore a `onException` sequel
  _ <- sequel
  return r

-- f runs masked; its argument runs an action in the state before
mask :: ((forall c . IO c -> IO c) -> IO b) -> IO b
mask f = do
  old <- primGetMask
  if old == 0
    then withMaskState 1 (f (withMaskState 0))
    else f (withMaskState old)

uninterruptibleMask :: ((forall c . IO c -> IO c) -> IO b) -> IO b
uninterruptibleMask f = do
  old <- primGetMask
  if old == 2
    then f (withMaskState 2)
    else withMaskState 2 (f (withMaskState old))

mask_ :: IO a -> IO a
mask_ act = mask (\_ -> act)

uninterruptibleMask_ :: IO a -> IO a
uninterruptibleMask_ act = uninterruptibleMask (\_ -> act)

assert :: Bool -> a -> a
assert True x  = x
assert False _ = error "Assertion failed"
