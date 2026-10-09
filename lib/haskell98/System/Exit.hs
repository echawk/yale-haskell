-- System.Exit: the Haskell 2010 library module (Report 2010, Part II), for Yale
-- Haskell's Haskell 98 dialect.  It re-exports the Haskell 98 module System
-- and the Prelude names the 2010 Report lists, plus what 2010 added.
module System.Exit (
    ExitCode(ExitSuccess, ExitFailure), exitWith, exitFailure, exitSuccess
  ) where

import System

exitSuccess :: IO a
exitSuccess = exitWith ExitSuccess
