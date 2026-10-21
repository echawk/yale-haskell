import qualified Control.Monad.ST.Safe as S
import qualified Control.Monad.ST.Lazy.Safe as L
main = print (S.runST (return 1), L.runST (return (2 :: Int)))
