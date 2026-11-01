import System.Posix.Types
import Foreign.C.Types
import System.Posix.Time

f :: EpochTime -> CTime
f t = t + 1

main :: IO ()
main = do
  t <- epochTime
  print (f 41)
  print (t > 1700000000)
