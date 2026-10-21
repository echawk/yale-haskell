import qualified GHC.Arr as A
import Data.Array.ST (newArray)
import Control.Monad.ST

main :: IO ()
main = do
  let arr = runST (do
        a <- newArray (1, 4) 0 :: ST s (A.STArray s Int Int)
        A.unsafeWriteSTArray a 2 7
        x <- A.unsafeReadSTArray a 2
        A.unsafeWriteSTArray a 0 (x + A.numElementsSTArray a)
        A.freezeSTArray a)
  print (arr, A.bounds arr)
  print (runST (A.thawSTArray arr >>= \a -> return (A.boundsSTArray a)))
