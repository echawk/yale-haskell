-- Library pieces from the Hackage survey: GHC.Event's timers (network,
-- auto-update), ShortByteString(SBS) (random), Builder's floatLE
-- (cereal), NonEmpty's isPrefixOf (aeson-pretty), traceEvent
-- (pretty-simple), GHC.Natural (unliftio), openBinaryTempFile (temporary).
{-# LANGUAGE MagicHash #-}
import Data.ByteString.Short.Internal (ShortByteString(SBS))
import GHC.Event
import Control.Concurrent
import qualified Data.ByteString.Short as BSS
import qualified Data.ByteString.Builder as B
import qualified Data.ByteString.Lazy as BL
import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty(..))
import Debug.Trace (traceEvent, traceWith)
import GHC.Natural (naturalToInteger, intToNatural)
import System.IO
import System.Directory (getTemporaryDirectory, removeFile)
import GHC.Exts (sizeofByteArray#, Int(I#))

main = do
  timers
  case BSS.pack [1, 2, 3] of SBS a -> print (I# (sizeofByteArray# a))
  print (BL.unpack (B.toLazyByteString (B.floatLE 1.0 <> B.doubleBE (-2.5))))
  print (NE.isPrefixOf [1, 2] (1 :| [2, 3 :: Int]))
  print (traceEvent "e" (traceWith (const "w") 'x'))
  print (naturalToInteger (intToNatural 5))
  tmp <- getTemporaryDirectory
  (p, h) <- openBinaryTempFile tmp "yale.bin"
  hClose h
  removeFile p
  putStrLn "temp ok"

timers :: IO ()
timers = do
  mgr <- getSystemTimerManager
  m <- newEmptyMVar
  k1 <- registerTimeout mgr 20000 (putMVar m "first")
  k2 <- registerTimeout mgr 10000 (putMVar m "cancelled")
  unregisterTimeout mgr k2
  updateTimeout mgr k1 30000
  takeMVar m >>= putStrLn
  threadDelay 30000
  isEmptyMVar m >>= print
