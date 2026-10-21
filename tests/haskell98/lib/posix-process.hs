import System.Posix.Process (getProcessID)
import qualified System.Posix as P
main = do
  a <- getProcessID
  b <- P.getProcessID
  print (a == b, a > 0)
