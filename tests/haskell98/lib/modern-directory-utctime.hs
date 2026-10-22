import System.Directory
import Data.Time.Clock
main = do
  d <- getTemporaryDirectory
  let f = d ++ "/yale-modern-directory-utctime.txt"
  writeFile f "x"
  t <- getModificationTime f
  c <- getCurrentTime
  print (diffUTCTime c t >= 0 && diffUTCTime c t < 3600)
