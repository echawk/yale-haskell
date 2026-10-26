-- Library pieces from the Hackage survey: QSem and QSemN (unliftio),
-- NonEmpty's unfold (aeson-pretty), liftShrink2 (pandoc-types),
-- threadWaitReadSTM and unix's createPipe (network), and
-- Data.ByteString.Short's SBS (digest).
import Control.Concurrent
import Control.Concurrent.QSem
import Control.Concurrent.QSemN
import Control.Concurrent.STM
import qualified Data.List.NonEmpty as NE
import Test.QuickCheck (liftShrink2, shrink)
import System.Posix.IO (createPipe, fdWriteBuf)
import Foreign.Marshal.Array (withArray)
import qualified Data.ByteString.Short as BSS

main = do
  s <- newQSem 1
  waitQSem s
  signalQSem s
  waitQSem s
  putStrLn "qsem"
  n <- newQSemN 5
  waitQSemN n 3
  signalQSemN n 1
  waitQSemN n 3
  putStrLn "qsemn"
  print (NE.toList (NE.unfold (\ n -> (n, if n < 3 then Just (n + 1) else Nothing)) (1 :: Int)))
  print (liftShrink2 shrink shrink (2 :: Int, True))
  (r, w) <- createPipe
  _ <- withArray [120] (\ p -> fdWriteBuf w p 1)
  (wait, _) <- threadWaitReadSTM r
  atomically wait
  putStrLn "readable"
  print (case BSS.pack [7, 8] of BSS.SBS a -> BSS.length (BSS.SBS a))
