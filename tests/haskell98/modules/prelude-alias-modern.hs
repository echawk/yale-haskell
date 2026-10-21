import Prelude as P
import qualified Prelude as Q
main :: IO ()
main = P.print (P.traverse Just [1, 2 :: Int], Q.sequenceA [Just (3 :: Int)], P.foldMap show [4 :: Int])
