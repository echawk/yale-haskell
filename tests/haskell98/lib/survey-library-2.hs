-- More library pieces from the Hackage survey: pdep#/pext# (bitvec),
-- System.Process' Pid, getPid and createPipe (typed-process), throwTo in
-- Control.Exception (unliftio), NonEmpty's intersperse (base-compat),
-- lazy ByteString's Empty and Chunk with ByteString(..) (base16-
-- bytestring), getTerminalSize (tasty), and a synonym with an unused
-- parameter (cmdargs' AnyT).
{-# LANGUAGE MagicHash #-}
import GHC.Exts (pdep#, pext#)
import System.Process
import System.IO
import qualified Control.Exception as E
import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty(..))
import Data.ByteString.Lazy.Internal (ByteString(..))
import qualified Data.ByteString.Lazy as L
import System.Console.ANSI (getTerminalSize)

type AnyT t = Int
cons :: AnyT a -> AnyT [a] -> [Int]
cons x y = [x, y]

chunks :: ByteString -> Int
chunks Empty = 0
chunks (Chunk _ rest) = 1 + chunks rest

main :: IO ()
main = do
  print (pdep# 5 0xF0, pext# 0xA0 0xF0)
  (r, w) <- createPipe
  hPutStrLn w "through a pipe" >> hClose w
  hGetLine r >>= putStrLn
  (_, _, _, ph) <- createProcess (proc "true" [])
  pid <- getPid ph
  _ <- waitForProcess ph
  print (fmap (> 0) pid)
  print (NE.intersperse 0 (1 :| [2, 3]))
  print (chunks (L.pack [1, 2]), cons 1 2)
  getTerminalSize >>= print
