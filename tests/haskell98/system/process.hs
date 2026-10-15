-- System.Process: pipes, exit codes, signals, cwd and env, the read* functions.
import System.Process
import System.IO
import System.Exit
import Control.Exception (catch)

main :: IO ()
main = do
  readProcess "tr" ["a-z", "A-Z"] "hello\n" >>= putStr
  r <- readProcessWithExitCode "sh" ["-c", "echo out; echo err >&2; exit 3"] ""
  print r
  (Just i, Just o, Nothing, ph) <- createProcess (proc "sort" []) { std_in = CreatePipe, std_out = CreatePipe }
  hPutStr i "pear\napple\nfig\n"
  hClose i
  s <- hGetContents o
  putStr s
  waitForProcess ph >>= print
  waitForProcess ph >>= print
  hFlush stdout
  callProcess "echo" ["call", "process"]
  callCommand "echo call command"
  system "exit 2" >>= print
  rawSystem "true" [] >>= print
  readCreateProcess (shell "pwd") { cwd = Just "/" } "" >>= putStr
  readCreateProcess (shell "echo $FOO") { env = Just [("FOO", "bar")] } "" >>= putStr
  ph2 <- spawnProcess "sleep" ["10"]
  getProcessExitCode ph2 >>= print
  terminateProcess ph2
  c <- waitForProcess ph2
  print (c /= ExitSuccess)
  withCreateProcess (shell "echo with") { std_out = CreatePipe } $ \_ (Just h) _ ph -> do
    hGetLine h >>= putStrLn
    waitForProcess ph >>= print
  r2 <- (readProcess "false" [] "" >> return "no error") `catchIO` (return . show)
  putStrLn r2
  hFlush stdout
 where catchIO :: IO a -> (IOError -> IO a) -> IO a
       catchIO = catch
