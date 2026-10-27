-- Library pieces from the Hackage survey: TChan as stm's (broadcast,
-- dupTChan, cloneTChan: unliftio), NonEmpty's nubBy (aeson-pretty),
-- GHC.Event's getSystemEventManager (network), GHC.Conc.Sync (auto-update),
-- Data.Text.Internal.Builder (double-conversion).
import Control.Concurrent
import Control.Concurrent.STM
import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty(..))
import GHC.Event (getSystemEventManager)
import GHC.Conc.Sync (labelThread)
import qualified Data.Text.Internal.Builder as TB
import qualified Data.Text.Lazy as TL

main = do
  b <- newBroadcastTChanIO
  r1 <- atomically (dupTChan b)
  r2 <- atomically (dupTChan b)
  atomically (mapM_ (writeTChan b) [1, 2, 3 :: Int])
  xs <- atomically (sequence [readTChan r1, readTChan r1])
  ys <- atomically (sequence [readTChan r2, readTChan r2, readTChan r2])
  r3 <- atomically (cloneTChan r1)
  z <- atomically (readTChan r3)
  z' <- atomically (readTChan r1)
  print (xs, ys, z, z')
  c <- newTChanIO
  _ <- forkIO (atomically (writeTChan c "hi"))
  atomically (readTChan c) >>= putStrLn
  print (NE.toList (NE.nubBy (\a b -> a `mod` 3 == b `mod` 3) (1 :| [2, 4, 5, 6 :: Int])))
  m <- getSystemEventManager
  print (maybe "no event manager" (const "event manager") m)
  me <- myThreadId
  labelThread me "main"
  print (TL.unpack (TB.toLazyText (TB.fromString "built")))
