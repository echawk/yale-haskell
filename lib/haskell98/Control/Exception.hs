-- Control.Exception (base, a subset), for Yale Haskell's Haskell 98
-- dialect.  An exception is a Lisp condition (src/base/base-runtime.lisp):
-- an IOError, an ErrorCall (error, a failed pattern match) or an
-- ArithException (division by zero).  catch and try catch all three,
-- including runtime errors raised by pure code evaluated inside the
-- action.  There is no extensible hierarchy (no existential types; the
-- SomeException constructor holds the host's condition, which Show shows):
-- Exception has instances for SomeException, IOException, ErrorCall and
-- ArithException only, and ExitCode is not an exception (exitWith is not
-- caught).
module Control.Exception (
    SomeException(SomeException), IOException, ErrorCall(ErrorCall), ArithException(..),
    Exception(toException, fromException, displayException),
    catch, catches, handle, try, evaluate, throw, throwIO,
    bracket, bracket_, bracketOnError, finally, onException, mask_, uninterruptibleMask_,
    assert
  ) where

import Prelude hiding (catch)
import PreludeIO (IOError(..))
import BasePrims

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

class Show e => Exception e where
  toException      :: e -> SomeException
  fromException    :: SomeException -> Maybe e
  displayException :: e -> String

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

catches :: IO a -> [IO a -> IO a] -> IO a
catches action handlers = foldr (\h a -> h a) action handlers

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
mask_ :: IO a -> IO a
mask_ = id

uninterruptibleMask_ :: IO a -> IO a
uninterruptibleMask_ = id

assert :: Bool -> a -> a
assert True x  = x
assert False _ = error "Assertion failed"
