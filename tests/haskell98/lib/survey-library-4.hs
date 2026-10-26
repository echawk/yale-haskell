-- Library pieces from the Hackage survey: lazy ByteString's
-- foldlChunks (digest), Binary ShortByteString (pandoc-types),
-- NonEmpty's append (aeson-pretty), mkWeakMVar (unliftio).
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Short as SBS
import Data.Binary (encode, decode)
import qualified Data.List.NonEmpty as NE
import Data.List.NonEmpty (NonEmpty(..))
import Control.Concurrent.MVar
import System.Mem.Weak (deRefWeak)

main :: IO ()
main = do
  let lbs = BL.fromChunks [B.pack [1,2,3], B.pack [4,5]]
  print (BL.foldlChunks (\n c -> n + B.length c) 0 lbs)
  print (BL.foldrChunks (\c n -> B.length c : n) [] lbs)
  let s = SBS.pack [104,105,0,255]
  print (decode (encode s) == s)
  print (NE.toList (NE.append (1 :| [2]) (3 :| [4 :: Int])))
  m <- newMVar 'x'
  w <- mkWeakMVar m (return ())
  r <- deRefWeak w
  case r of
    Just m' -> readMVar m' >>= print
    Nothing -> putStrLn "gone"
