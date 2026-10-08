-- System.hs -- the Haskell 98 System library
--
-- Interface as in the Haskell 98 Library Report, chapter 13.
--
-- Stopgaps until the Prelude is H98 (see lib/haskell98/README.md):
--   * The Prelude still exports the Haskell 1.2 Dialogue versions of
--     getArgs, getProgName and getEnv, so this module hides them, and
--     so must any program that imports System.
--   * Errors (getEnv of an unset variable, system on a Lisp without
--     process support) are IOErrors signalled by the primitives; catch
--     them with IO.catch.

module System (
    ExitCode(ExitSuccess,ExitFailure),
    getArgs, getProgName, getEnv, system, exitWith, exitFailure
  ) where

import SystemPrims

data ExitCode = ExitSuccess | ExitFailure Int
                deriving (Eq, Ord, Show, Read)

getArgs                 :: IO [String]
getArgs                 =  primGetArgs

getProgName             :: IO String
getProgName             =  primGetProgName

-- Raises isDoesNotExistError if the variable is not set.
getEnv                  :: String -> IO String
getEnv                  =  primGetEnv

system                  :: String -> IO ExitCode
system cmd              =  primSystem cmd `thenIO` \n ->
                           returnIO (if n == 0 then ExitSuccess
                                               else ExitFailure n)

exitWith                :: ExitCode -> IO a
exitWith ExitSuccess    =  primExitWith 0
exitWith (ExitFailure n)
  | n == 0              =  error "exitWith: ExitFailure 0"
  | otherwise           =  primExitWith n

exitFailure             :: IO a
exitFailure             =  exitWith (ExitFailure 1)
