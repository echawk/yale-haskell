{-# LANGUAGE RankNTypes #-}
-- System.Console.Haskeline (haskeline), without line editing: lines are
-- read from standard input, the prompt written before each.  Completion
-- settings are accepted and not used; history is kept in memory.
module System.Console.Haskeline (
    InputT, runInputT, runInputTBehavior, haveTerminalUI, mapInputT,
    Behavior, defaultBehavior, useFile, useFileHandle, preferTerm,
    getInputLine, getInputLineWithInitial, getInputChar, getPassword,
    waitForAnyKey, outputStr, outputStrLn, getExternalPrint,
    Settings(Settings, complete, historyFile, autoAddHistory),
    defaultSettings, setComplete,
    getHistory, putHistory, modifyHistory,
    CompletionFunc, Completion(Completion, replacement, display, isFinished),
    completeWord, completeWord', completeWordWithPrev, completeQuotedWord,
    completeFilename, listFiles, noCompletion, simpleCompletion,
    fallbackCompletion, filenameWordBreakChars,
    withInterrupt, handleInterrupt, Interrupt(Interrupt),
    MonadException(catch), handle, throwIO
  ) where

import Prelude hiding (catch)
import PreludeModern (Applicative(pure, (<*>)))
import Control.Monad.Trans.Class (MonadTrans(lift))
import Control.Monad.IO.Class (MonadIO(liftIO))
import System.IO
import System.Console.Haskeline.History
import qualified Control.Exception as E
import Control.Exception (Exception, throwIO)

newtype InputT m a = InputT (History -> m (a, History))

unInputT :: InputT m a -> History -> m (a, History)
unInputT (InputT f) = f

-- haskeline before 0.8: catching in IO and in InputT over it (0.8 has
-- exceptions' MonadCatch instead; Agda's Interaction.Monad takes this one
-- when MIN_VERSION_haskeline(0,8,0) is false, as it is here)
class Monad m => MonadException m where
  catch :: Exception e => m a -> (e -> m a) -> m a

instance MonadException IO where
  catch = E.catch

instance MonadException m => MonadException (InputT m) where
  catch (InputT f) h = InputT (\hist -> f hist `catch` (\e -> unInputT (h e) hist))

handle :: (MonadException m, Exception e) => (e -> m a) -> m a -> m a
handle h m = m `catch` h

instance Monad m => Functor (InputT m) where
  fmap f (InputT g) = InputT (\h -> g h >>= \(a, h') -> return (f a, h'))

instance Monad m => Applicative (InputT m) where
  pure a = InputT (\h -> return (a, h))
  InputT f <*> InputT x = InputT (\h -> f h >>= \(g, h1) -> x h1 >>= \(a, h2) -> return (g a, h2))

instance Monad m => Monad (InputT m) where
  return a = InputT (\h -> return (a, h))
  InputT m >>= k = InputT (\h -> m h >>= \(a, h') -> unInputT (k a) h')

instance MonadTrans InputT where
  lift m = InputT (\h -> m >>= \a -> return (a, h))

instance MonadIO m => MonadIO (InputT m) where
  liftIO io = lift (liftIO io)

data Settings m = Settings { complete :: CompletionFunc m,
                             historyFile :: Maybe FilePath,
                             autoAddHistory :: Bool }

defaultSettings :: MonadIO m => Settings m
defaultSettings = Settings noCompletion Nothing True

setComplete :: CompletionFunc m -> Settings m -> Settings m
setComplete f s = s { complete = f }

data Behavior = Behavior

defaultBehavior, preferTerm :: Behavior
defaultBehavior = Behavior
preferTerm = Behavior

useFile :: FilePath -> Behavior
useFile _ = Behavior

useFileHandle :: Handle -> Behavior
useFileHandle _ = Behavior

runInputT :: MonadIO m => Settings m -> InputT m a -> m a
runInputT _ (InputT f) = f emptyHistory >>= return . fst

runInputTBehavior :: MonadIO m => Behavior -> Settings m -> InputT m a -> m a
runInputTBehavior _ = runInputT

haveTerminalUI :: Monad m => InputT m Bool
haveTerminalUI = return False

mapInputT :: (forall b . m b -> m b) -> InputT m a -> InputT m a
mapInputT g (InputT f) = InputT (\h -> g (f h))

getHistory :: Monad m => InputT m History
getHistory = InputT (\h -> return (h, h))

putHistory :: Monad m => History -> InputT m ()
putHistory h = InputT (\_ -> return ((), h))

modifyHistory :: Monad m => (History -> History) -> InputT m ()
modifyHistory f = InputT (\h -> return ((), f h))

-- The prompt, then a line of standard input; Nothing at its end.
getInputLine :: MonadIO m => String -> InputT m (Maybe String)
getInputLine prompt = do
  liftIO (putStr prompt >> hFlush stdout)
  eof <- liftIO isEOF
  if eof
    then return Nothing
    else do
      l <- liftIO getLine
      modifyHistory (addHistoryUnlessConsecutiveDupe l)
      return (Just l)

getInputLineWithInitial :: MonadIO m => String -> (String, String) -> InputT m (Maybe String)
getInputLineWithInitial prompt _ = getInputLine prompt

getInputChar :: MonadIO m => String -> InputT m (Maybe Char)
getInputChar prompt = do
  liftIO (putStr prompt >> hFlush stdout)
  eof <- liftIO isEOF
  if eof then return Nothing else fmap Just (liftIO getChar)

getPassword :: MonadIO m => Maybe Char -> String -> InputT m (Maybe String)
getPassword _ = getInputLine

waitForAnyKey :: MonadIO m => String -> InputT m Bool
waitForAnyKey prompt = fmap (maybe False (const True)) (getInputChar prompt)

outputStr, outputStrLn :: MonadIO m => String -> InputT m ()
outputStr s = liftIO (putStr s)
outputStrLn s = liftIO (putStrLn s)

getExternalPrint :: MonadIO m => InputT m (String -> IO ())
getExternalPrint = return putStr

-- Completion: accepted, not used.
type CompletionFunc m = (String, String) -> m (String, [Completion])

data Completion = Completion { replacement :: String, display :: String,
                               isFinished :: Bool }
  deriving (Eq, Ord, Show)

simpleCompletion :: String -> Completion
simpleCompletion s = Completion s s True

noCompletion :: Monad m => CompletionFunc m
noCompletion (l, _) = return (l, [])

completeWord :: Monad m => Maybe Char -> [Char] -> (String -> m [Completion]) -> CompletionFunc m
completeWord _ breaks f (l, r) = do
  let (word, rest) = break (`elem` breaks) l
  cs <- f (reverse word)
  return (rest, cs)

completeWord' :: Monad m => Maybe Char -> (Char -> Bool) -> (String -> m [Completion]) -> CompletionFunc m
completeWord' _ isBreak f (l, _) = do
  let (word, rest) = break isBreak l
  cs <- f (reverse word)
  return (rest, cs)

completeWordWithPrev :: Monad m => Maybe Char -> [Char] -> (String -> String -> m [Completion]) -> CompletionFunc m
completeWordWithPrev _ breaks f (l, _) = do
  let (word, rest) = break (`elem` breaks) l
  cs <- f rest (reverse word)
  return (rest, cs)

completeQuotedWord :: Monad m => Maybe Char -> [Char] -> (String -> m [Completion]) -> CompletionFunc m -> CompletionFunc m
completeQuotedWord _ _ _ alt = alt

completeFilename :: MonadIO m => CompletionFunc m
completeFilename = noCompletion

listFiles :: MonadIO m => FilePath -> m [Completion]
listFiles _ = return []

fallbackCompletion :: Monad m => CompletionFunc m -> CompletionFunc m -> CompletionFunc m
fallbackCompletion a b input = do
  r@(_, cs) <- a input
  if null cs then b input else return r

filenameWordBreakChars :: String
filenameWordBreakChars = " \t\n`@$><=;|&{("

data Interrupt = Interrupt deriving (Show, Eq)

withInterrupt :: InputT m a -> InputT m a
withInterrupt a = a

handleInterrupt :: Monad m => m a -> m a -> m a
handleInterrupt _ a = a
