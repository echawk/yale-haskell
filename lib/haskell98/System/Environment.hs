-- System.Environment: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module System
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.Environment (getArgs, getProgName, getEnv, lookupEnv, setEnv, unsetEnv,
                           getEnvironment, withArgs, withProgName,
                           getExecutablePath, executablePath) where

import System hiding (getArgs, getProgName)
import qualified System as S
import BasePrims
import Data.IORef
import System.IO.Unsafe (unsafePerformIO)
import Control.Exception (finally)

-- withArgs and withProgName override what the program was given
{-# NOINLINE argsOverride #-}
argsOverride :: IORef (Maybe [String])
argsOverride = unsafePerformIO (newIORef Nothing)

{-# NOINLINE progOverride #-}
progOverride :: IORef (Maybe String)
progOverride = unsafePerformIO (newIORef Nothing)

getArgs :: IO [String]
getArgs = readIORef argsOverride >>= maybe S.getArgs return

getProgName :: IO String
getProgName = readIORef progOverride >>= maybe S.getProgName return

withArgs :: [String] -> IO a -> IO a
withArgs xs act = do
  old <- readIORef argsOverride
  writeIORef argsOverride (Just xs)
  act `finally` writeIORef argsOverride old

withProgName :: String -> IO a -> IO a
withProgName n act = do
  old <- readIORef progOverride
  writeIORef progOverride (Just n)
  act `finally` writeIORef progOverride old

-- (the program's name as given: the path of the executable is not known)
getExecutablePath :: IO FilePath
getExecutablePath = S.getProgName

executablePath :: Maybe (IO (Maybe FilePath))
executablePath = Nothing

lookupEnv :: String -> IO (Maybe String)
lookupEnv name = do
  set <- primEnvIsSet name
  if set then primEnvValue name >>= return . Just else return Nothing

setEnv :: String -> String -> IO ()
setEnv name "" = primUnsetEnv name
setEnv name v  = primSetEnv name v

unsetEnv :: String -> IO ()
unsetEnv = primUnsetEnv

getEnvironment :: IO [(String, String)]
getEnvironment = fmap (map entry . split) primEnvironment
  where split "" = []
        split s = case break (== '\0') s of (e, rest) -> e : split (drop 1 rest)
        entry e = case break (== '=') e of (n, v) -> (n, drop 1 v)
