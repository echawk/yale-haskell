-- System.Process (the process package's API, most of it), for Yale
-- Haskell: processes over uiop:launch-program and run-program
-- (src/base/base-runtime.lisp).  Not here: process groups and signals
-- other than terminateProcess, Windows-only fields, and the Pid.
module System.Process (
    CreateProcess(..), CmdSpec(..), StdStream(..), ProcessHandle,
    createProcess, createProcess_, shell, proc,
    callProcess, callCommand, spawnProcess, spawnCommand,
    readCreateProcess, readProcess,
    readCreateProcessWithExitCode, readProcessWithExitCode,
    withCreateProcess, cleanupProcess,
    waitForProcess, getProcessExitCode, terminateProcess,
    showCommandForUser, system, rawSystem
  ) where

import System.Exit
import System.IO
import IOBase (Handle(..))
import BasePrims
import IOPrims (HandleObj)
import Data.IORef
import Data.List (intercalate)
import Control.Exception (bracket, onException)

data CmdSpec = ShellCommand String
             | RawCommand FilePath [String]
  deriving (Eq, Show)

data StdStream = Inherit | UseHandle Handle | CreatePipe | NoStream
  deriving Eq

data CreateProcess = CreateProcess {
    cmdspec            :: CmdSpec,
    cwd                :: Maybe FilePath,
    env                :: Maybe [(String, String)],
    std_in             :: StdStream,
    std_out            :: StdStream,
    std_err            :: StdStream,
    close_fds          :: Bool,
    create_group       :: Bool,
    delegate_ctlc      :: Bool,
    detach_console     :: Bool,
    create_new_console :: Bool,
    new_session        :: Bool,
    use_process_jobs   :: Bool
  }

-- the process, and its exit code once known
data ProcessHandle = ProcessHandle Proc (IORef (Maybe ExitCode))

shell :: String -> CreateProcess
shell s = defaultCreateProcess (ShellCommand s)

proc :: FilePath -> [String] -> CreateProcess
proc p args = defaultCreateProcess (RawCommand p args)

defaultCreateProcess :: CmdSpec -> CreateProcess
defaultCreateProcess c = CreateProcess {
    cmdspec = c, cwd = Nothing, env = Nothing,
    std_in = Inherit, std_out = Inherit, std_err = Inherit,
    close_fds = False, create_group = False, delegate_ctlc = False,
    detach_console = False, create_new_console = False,
    new_session = False, use_process_jobs = False }

-- the words of a command, joined by NULs for the primitives
argv :: CmdSpec -> String
argv (ShellCommand s)   = joinNul ["/bin/sh", "-c", s]
argv (RawCommand p as)  = joinNul (p : as)

joinNul :: [String] -> String
joinNul = intercalate "\0"

envArgs :: Maybe [(String, String)] -> (Bool, String)
envArgs Nothing   = (False, "")
envArgs (Just kv) = (True, joinNul [k ++ "=" ++ v | (k, v) <- kv])

streamArg :: StdStream -> (Int, HandleObj)
streamArg Inherit                = (0, stdObj)
streamArg CreatePipe             = (1, stdObj)
streamArg NoStream               = (2, stdObj)
streamArg (UseHandle (Handle h)) = (3, h)

stdObj :: HandleObj
stdObj = case stdin of Handle h -> h

createProcess :: CreateProcess
              -> IO (Maybe Handle, Maybe Handle, Maybe Handle, ProcessHandle)
createProcess cp = do
  let (hasEnv, e) = envArgs (env cp)
      (im, ih) = streamArg (std_in cp)
      (om, oh) = streamArg (std_out cp)
      (em, eh) = streamArg (std_err cp)
  p <- primLaunchProcess (argv (cmdspec cp)) (maybe "" id (cwd cp)) hasEnv e
                         im ih om oh em eh
  i <- pipe p 0 (std_in cp)
  o <- pipe p 1 (std_out cp)
  r <- pipe p 2 (std_err cp)
  code <- newIORef Nothing
  return (i, o, r, ProcessHandle p code)
 where
  pipe p n CreatePipe = primProcessHandle p n >>= return . Just . Handle
  pipe _ _ _          = return Nothing

createProcess_ :: String -> CreateProcess
               -> IO (Maybe Handle, Maybe Handle, Maybe Handle, ProcessHandle)
createProcess_ _ = createProcess

toExitCode :: Int -> ExitCode
toExitCode 0 = ExitSuccess
toExitCode n = ExitFailure n

waitForProcess :: ProcessHandle -> IO ExitCode
waitForProcess (ProcessHandle p ref) = do
  known <- readIORef ref
  case known of
    Just c  -> return c
    Nothing -> do
      c <- primWaitProcess p >>= return . toExitCode
      writeIORef ref (Just c)
      return c

getProcessExitCode :: ProcessHandle -> IO (Maybe ExitCode)
getProcessExitCode ph@(ProcessHandle p ref) = do
  known <- readIORef ref
  case known of
    Just c  -> return (Just c)
    Nothing -> do
      running <- primProcessRunning p
      if running then return Nothing
        else waitForProcess ph >>= return . Just

terminateProcess :: ProcessHandle -> IO ()
terminateProcess (ProcessHandle p _) = primTerminateProcess p

cleanupProcess :: (Maybe Handle, Maybe Handle, Maybe Handle, ProcessHandle) -> IO ()
cleanupProcess (i, o, e, ph) = do
  terminateProcess ph
  mapM_ (maybe (return ()) hClose) [i, o, e]
  _ <- waitForProcess ph
  return ()

withCreateProcess :: CreateProcess
                  -> (Maybe Handle -> Maybe Handle -> Maybe Handle -> ProcessHandle -> IO a)
                  -> IO a
withCreateProcess cp act =
  bracket (createProcess cp) cleanupProcess (\(i, o, e, ph) -> act i o e ph)

spawnProcess :: FilePath -> [String] -> IO ProcessHandle
spawnProcess p args = createProcess (proc p args) >>= \(_, _, _, ph) -> return ph

spawnCommand :: String -> IO ProcessHandle
spawnCommand s = createProcess (shell s) >>= \(_, _, _, ph) -> return ph

callProcess :: FilePath -> [String] -> IO ()
callProcess p args = do
  c <- spawnProcess p args >>= waitForProcess
  checkExit "callProcess" (showCommandForUser p args) c

callCommand :: String -> IO ()
callCommand s = do
  c <- spawnCommand s >>= waitForProcess
  checkExit "callCommand" s c

checkExit :: String -> String -> ExitCode -> IO ()
checkExit _ _ ExitSuccess = return ()
checkExit fun cmd (ExitFailure n) =
  primProcessFailed (fun ++ ": " ++ cmd ++ " (exit " ++ show n ++ ")")

system :: String -> IO ExitCode
system s = spawnCommand s >>= waitForProcess

rawSystem :: String -> [String] -> IO ExitCode
rawSystem p args = spawnProcess p args >>= waitForProcess

readFull :: Bool -> CreateProcess -> String -> IO (ExitCode, String, String)
readFull captureErr cp input = do
  let (hasEnv, e) = envArgs (env cp)
  out <- primReadProcessFull (argv (cmdspec cp)) (maybe "" id (cwd cp)) hasEnv e
                             input captureErr
  code <- primLastExitCode
  err <- primLastStderr
  return (toExitCode code, out, err)

readCreateProcessWithExitCode :: CreateProcess -> String -> IO (ExitCode, String, String)
readCreateProcessWithExitCode = readFull True

readProcessWithExitCode :: FilePath -> [String] -> String -> IO (ExitCode, String, String)
readProcessWithExitCode p args = readFull True (proc p args)

readCreateProcess :: CreateProcess -> String -> IO String
readCreateProcess cp input = do
  (code, out, _) <- readFull False cp input
  checkExit "readCreateProcess" (cmdText (cmdspec cp)) code
  return out

readProcess :: FilePath -> [String] -> String -> IO String
readProcess p args = readCreateProcess (proc p args)

cmdText :: CmdSpec -> String
cmdText (ShellCommand s)  = s
cmdText (RawCommand p as) = showCommandForUser p as

-- a command line, quoting each word for the shell
showCommandForUser :: FilePath -> [String] -> String
showCommandForUser prog args = unwords (map quote (prog : args))
  where quote w | all safe w && not (null w) = w
                | otherwise = "'" ++ concatMap esc w ++ "'"
        esc '\'' = "'\\''"
        esc c    = [c]
        safe c = c `elem` "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./=:,+@%"
