-- System.Process (the process package, a subset), for Yale Haskell: run
-- a command through /bin/sh.
module System.Process (callCommand, system, rawSystem, readProcess,
                       readProcessWithExitCode, showCommandForUser) where

import System.Exit
import BasePrims

toExitCode :: Int -> ExitCode
toExitCode 0 = ExitSuccess
toExitCode n = ExitFailure n

system :: String -> IO ExitCode
system cmd = primSystem cmd >>= return . toExitCode

callCommand :: String -> IO ()
callCommand cmd = do
  r <- primSystem cmd
  if r == 0 then return ()
    else ioError (userError ("callCommand: " ++ cmd ++ " (exit " ++ show r ++ "): failed"))

rawSystem :: String -> [String] -> IO ExitCode
rawSystem prog args = system (showCommandForUser prog args)

readProcess :: FilePath -> [String] -> String -> IO String
readProcess prog args input = do
  (code, out, _) <- readProcessWithExitCode prog args input
  case code of
    ExitSuccess -> return out
    ExitFailure n -> ioError (userError ("readProcess: " ++ showCommandForUser prog args
                                         ++ " (exit " ++ show n ++ "): failed"))

-- standard error is not captured: it goes to ours, and "" is returned
readProcessWithExitCode :: FilePath -> [String] -> String -> IO (ExitCode, String, String)
readProcessWithExitCode prog args input = do
  let cmd = showCommandForUser prog args
  out <- primReadProcessOutput cmd input
  code <- primLastExitCode
  return (toExitCode code, out, "")

-- a command line, quoting each word for the shell
showCommandForUser :: FilePath -> [String] -> String
showCommandForUser prog args = unwords (map quote (prog : args))
  where quote w | all safe w && not (null w) = w
                | otherwise = "'" ++ concatMap esc w ++ "'"
        esc '\'' = "'\\''"
        esc c    = [c]
        safe c = c `elem` "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./=:,+@%"
