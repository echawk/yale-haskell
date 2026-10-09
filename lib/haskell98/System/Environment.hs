-- System.Environment: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module System
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.Environment (getArgs, getProgName, getEnv, lookupEnv, setEnv, unsetEnv) where

import System
import BasePrims

lookupEnv :: String -> IO (Maybe String)
lookupEnv name = do
  set <- primEnvIsSet name
  if set then primEnvValue name >>= return . Just else return Nothing

setEnv :: String -> String -> IO ()
setEnv name "" = primUnsetEnv name
setEnv name v  = primSetEnv name v

unsetEnv :: String -> IO ()
unsetEnv = primUnsetEnv
