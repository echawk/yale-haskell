import System.Process
import System.Posix.Signals (signalProcess, sigTERM)
import System.Exit

main :: IO ()
main = do
  (r, w) <- createPipeFd
  print (r >= 0 && w > r)
  (_, _, _, ph) <- createProcess (proc "sleep" ["10"])
  Just pid <- getPid ph
  signalProcess sigTERM pid
  code <- waitForProcess ph
  print (code /= ExitSuccess)
