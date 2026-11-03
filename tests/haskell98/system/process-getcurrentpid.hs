-- System.Process.getCurrentPid
import System.Process (getCurrentPid)
main :: IO ()
main = getCurrentPid >>= \p -> print (p > 0)
