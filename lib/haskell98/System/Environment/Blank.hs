-- System.Environment.Blank (base): the environment, an unset variable
-- Nothing rather than an error, and setEnv that may keep a value.
module System.Environment.Blank (
    getArgs, getProgName, getEnvironment, getEnv, getEnvDefault, setEnv,
    unsetEnv
  ) where

import System.Environment (getArgs, getProgName, getEnvironment, lookupEnv)
import qualified System.Environment as E

getEnv :: String -> IO (Maybe String)
getEnv = lookupEnv

getEnvDefault :: String -> String -> IO String
getEnvDefault name def = fmap (maybe def id) (lookupEnv name)

-- with the flag False, an already set variable is kept
setEnv :: String -> String -> Bool -> IO ()
setEnv name value overwrite = do
  old <- lookupEnv name
  case old of
    Just _ | not overwrite -> return ()
    _ -> E.setEnv name value

unsetEnv :: String -> IO ()
unsetEnv = E.unsetEnv
