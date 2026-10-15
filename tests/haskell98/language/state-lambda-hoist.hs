-- One-shot state lambdas (optimize.mumble's state-lambda?): bindings move
-- into IO and ST state lambdas.  Results must not change: loops over
-- IORefs and STRefs, an action shared and run several times, and a
-- binding that is bottom unless the action runs.
import Data.IORef
import Control.Monad
import Control.Monad.ST
import Data.STRef

sumST :: Int -> Int
sumST n = runST $ do
  r <- newSTRef 0
  let go i | i > n = return ()
           | otherwise = modifySTRef' r (+ i) >> go (i + 1)
  go 1
  readSTRef r

main :: IO ()
main = do
  r <- newIORef (0 :: Int)
  let loop i = let next = loop (i + 1)
               in if i > 1000 then return () else modifyIORef' r (+ i) >> next
  loop 1
  readIORef r >>= print
  let act = modifyIORef' r (* 2)
  act >> act >> act
  readIORef r >>= print
  print (sumST 10000)
  let never = let x = error "not run" :: Int in print x
  when False never
  c <- newIORef (0 :: Int)
  replicateM_ 5 (modifyIORef c (+ 1))
  readIORef c >>= print
