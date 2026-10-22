import qualified System.Time as T
import Time
main = do { c <- getClockTime; let { T.TOD s _ = c }; print (s > 0) ; print (T.TOD 5 0 < T.TOD 6 0) }
