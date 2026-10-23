import System.Environment.Blank
import System.Process
import System.IO
main = do
  setEnv "YALE_BLANK_T" "a" True
  setEnv "YALE_BLANK_T" "b" False
  getEnv "YALE_BLANK_T" >>= print
  getEnvDefault "YALE_NO_SUCH_VAR" "d" >>= putStrLn
  (i, o, e, p) <- runInteractiveCommand "tr a-z A-Z"
  hPutStr i "hello\n" >> hClose i
  hGetContents o >>= putStr
