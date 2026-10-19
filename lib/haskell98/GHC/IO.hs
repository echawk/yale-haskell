{-# LANGUAGE MagicHash, UnboxedTuples, PatternSynonyms, ViewPatterns #-}
-- GHC.IO (base): IO's representation, a function of the State# token
-- (GHC.PrimOps), for code that builds or takes apart IO actions.  Yale
-- Haskell's IO is its own state function; IO f runs f when the action
-- runs, and (IO f) as a pattern gives the function that runs the action
-- when it is applied to a token.
module GHC.IO (
    IO(IO), unIO, unsafePerformIO, unsafeInterleaveIO,
    unsafeDupablePerformIO, unsafeDupableInterleaveIO, stToIO, ioToST,
    unsafeIOToST, unsafeSTToIO, liftIO, failIO, mplusIO, noDuplicate,
    evaluate, throwIO, catch, mask, mask_, uninterruptibleMask,
    uninterruptibleMask_, onException, bracket, finally
  ) where

import Prelude hiding (catch)
import qualified Prelude as P
import GHC.PrimOps (State#, RealWorld)
import Unsafe.Coerce (unsafeCoerce)
import System.IO.Unsafe (unsafePerformIO, unsafeInterleaveIO,
                         unsafeDupablePerformIO)
import Control.Monad.ST (stToIO, ioToST, unsafeIOToST, unsafeSTToIO)
import Control.Exception (evaluate, throwIO, catch, mask, mask_,
                          uninterruptibleMask, uninterruptibleMask_,
                          onException, bracket, finally)

data Box a = Box a

-- an action from its state function: run when the action runs (the
-- token depends on the action's own run, so it is not shared)
mkIO :: (State# RealWorld -> (# State# RealWorld, a #)) -> P.IO a
mkIO m = P.return () P.>>= \u -> case m (unsafeCoerce u) of
                                  (# s, a #) -> s `seq` P.return a

-- the action's state function: running it once the token is evaluated
unIO :: P.IO a -> State# RealWorld -> (# State# RealWorld, a #)
unIO io s = case unsafePerformIO (s `seq` (io P.>>= \x -> P.return (Box x))) of
              Box x -> (# s, x #)

pattern IO :: (State# RealWorld -> (# State# RealWorld, a #)) -> P.IO a
pattern IO m <- (unIO -> m)
  where IO m = mkIO m

unsafeDupableInterleaveIO :: P.IO a -> P.IO a
unsafeDupableInterleaveIO = unsafeInterleaveIO

liftIO :: P.IO a -> P.IO a
liftIO = id

failIO :: String -> P.IO a
failIO s = ioError (userError s)

mplusIO :: P.IO a -> P.IO a -> P.IO a
mplusIO m n = m `catchIOError` \_ -> n
  where catchIOError a h = P.catch a h

noDuplicate :: P.IO ()
noDuplicate = P.return ()
