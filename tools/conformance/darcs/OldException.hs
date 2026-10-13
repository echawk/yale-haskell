-- OldException: the parts of base 3's Control.Exception (GHC 6.6) that
-- darcs 1.0.9 uses, over Yale Haskell's Control.Exception
-- (tools/conformance/darcs.py; the darcs patch imports this module where
-- darcs imported Control.Exception).  Exception is base 3's data type of
-- the kinds of exception; differences from base 3:
--
--   * exitWith is not an exception here, so ExitException is never caught
--     (throwIO (ExitException c) exits);
--   * a dynamic exception (throwDyn, catchDyn) carries its value without a
--     type: catchDyn's handler gets whatever value was thrown, so only one
--     type should be thrown dynamically where it may be caught;
--   * block and unblock do nothing (there are no asynchronous exceptions).
module OldException (
    Exception(IOException, ErrorCall, ExitException, AssertionFailed,
              ArithException, DynException),
    catch, catchJust, handle, handleJust, try, tryJust, throw, throwIO,
    evaluate, ioErrors, userErrors, errorCalls, assertions, dynExceptions,
    bracket, bracket_, finally, block, unblock,
    catchDyn, throwDyn, throwDynTo
  ) where

import Prelude hiding (catch)
import qualified Control.Exception as E
import System.Exit (ExitCode, exitWith)
import System.IO.Error (isUserError, ioeGetErrorString)
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)
import Unsafe.Coerce (unsafeCoerce)

data Dyn = Dyn

data Exception
  = IOException IOError
  | ErrorCall String
  | ExitException ExitCode
  | AssertionFailed String
  | ArithException E.ArithException
  | DynException Dyn

instance Show Exception where
  showsPrec _ (IOException e) = shows e
  showsPrec _ (ErrorCall m) = showString m
  showsPrec _ (ExitException c) = showString "exit: " . shows c
  showsPrec _ (AssertionFailed m) = showString m
  showsPrec _ (ArithException a) = shows a
  showsPrec _ (DynException _) = showString "unknown exception"

-- Dynamic exceptions are ErrorCalls with this prefix and a number, the
-- key of their value in dynTable.
dynPrefix :: String
dynPrefix = "\0darcs-dynamic-exception "

dynTable :: IORef (Int, [(Int, Dyn)])
dynTable = unsafePerformIO (newIORef (0, []))
{-# NOINLINE dynTable #-}

fromSome :: E.SomeException -> Exception
fromSome e =
  case E.fromException e of
    Just io -> IOException io
    Nothing -> case E.fromException e of
      Just (E.ErrorCall m)
        | take (length dynPrefix) m == dynPrefix ->
            let k = read (drop (length dynPrefix) m)
            in DynException (lookupDyn k)
        | otherwise -> ErrorCall m
      Nothing -> case E.fromException e of
        Just a -> ArithException a
        Nothing -> ErrorCall (show e)

lookupDyn :: Int -> Dyn
lookupDyn k = unsafePerformIO $ do
  (_, t) <- readIORef dynTable
  return (maybe Dyn id (lookup k t))

toSome :: Exception -> IO a
toSome (IOException e) = ioError e
toSome (ErrorCall m) = E.throwIO (E.ErrorCall m)
toSome (ExitException c) = exitWith c
toSome (AssertionFailed m) = E.throwIO (E.ErrorCall m)
toSome (ArithException a) = E.throwIO a
toSome (DynException d) = do
  k <- atomicModify (\(n, t) -> ((n + 1, (n, d) : t), n))
  E.throwIO (E.ErrorCall (dynPrefix ++ show k))
  where atomicModify f = do { v <- readIORef dynTable; let (v', r) = f v in writeIORef dynTable v' >> return r }

catch :: IO a -> (Exception -> IO a) -> IO a
catch act h = E.catch act (\e -> h (fromSome e))

handle :: (Exception -> IO a) -> IO a -> IO a
handle = flip catch

catchJust :: (Exception -> Maybe b) -> IO a -> (b -> IO a) -> IO a
catchJust p act h = catch act (\e -> maybe (toSome e) h (p e))

handleJust :: (Exception -> Maybe b) -> (b -> IO a) -> IO a -> IO a
handleJust p h act = catchJust p act h

try :: IO a -> IO (Either Exception a)
try act = catch (fmap Right act) (return . Left)

tryJust :: (Exception -> Maybe b) -> IO a -> IO (Either b a)
tryJust p act = catch (fmap Right act) (\e -> maybe (toSome e) (return . Left) (p e))

throw :: Exception -> a
throw e = unsafePerformIO (toSome e)

throwIO :: Exception -> IO a
throwIO = toSome

evaluate :: a -> IO a
evaluate = E.evaluate

ioErrors :: Exception -> Maybe IOError
ioErrors (IOException e) = Just e
ioErrors _ = Nothing

userErrors :: Exception -> Maybe String
userErrors (IOException e) | isUserError e = Just (ioeGetErrorString e)
userErrors _ = Nothing

errorCalls :: Exception -> Maybe String
errorCalls (ErrorCall m) = Just m
errorCalls _ = Nothing

assertions :: Exception -> Maybe String
assertions (AssertionFailed m) = Just m
assertions _ = Nothing

dynExceptions :: Exception -> Maybe Dyn
dynExceptions (DynException d) = Just d
dynExceptions _ = Nothing

bracket :: IO a -> (a -> IO b) -> (a -> IO c) -> IO c
bracket = E.bracket

bracket_ :: IO a -> IO b -> IO c -> IO c
bracket_ = E.bracket_

finally :: IO a -> IO b -> IO a
finally = E.finally

block, unblock :: IO a -> IO a
block act = act
unblock act = act

throwDyn :: a -> b
throwDyn x = throw (DynException (unsafeCoerce x))

throwDynTo :: t -> a -> IO ()
throwDynTo _ x = throwIO (DynException (unsafeCoerce x))

catchDyn :: IO a -> (e -> IO a) -> IO a
catchDyn act h = catch act (\e -> case e of
                                    DynException d -> h (unsafeCoerce d)
                                    _ -> toSome e)
