-- Library pieces packages use (the Hackage survey): Foreign.Marshal.Pool,
-- bytestring's PS, unfoldrN, memcpy and foldlChunks, GHC.Exts'
-- unpackCString#, GHC.Conc's closeFdWith, GHC.IO.Device.
{-# LANGUAGE MagicHash, PatternSynonyms #-}
module Main (main, type (~)) where
import Foreign.Marshal.Pool
import Foreign.Storable
import Foreign.Ptr
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as BI
import qualified Data.ByteString.Lazy as L
import qualified Data.ByteString.Lazy.Internal as LI
import Data.Word (Word8)
import GHC.Exts (unpackCString#)
import GHC.Conc (closeFdWith)
import GHC.IO.Device (IODeviceType(..))
import System.Posix.Types (Fd(..))
main :: IO ()
main = do
  s <- withPool $ \pool -> do
    p <- pooledNewArray pool [1, 2, 3 :: Int]
    q <- pooledMallocArray pool 3 :: IO (Ptr Int)
    BI.memcpy (castPtr q) (castPtr p) (3 * sizeOf (0 :: Int))
    mapM (peekElemOff q) [0 .. 2]
  print s
  let BI.PS _ off len = B.pack [104, 105]
  print (off, len, B.unfoldrN 3 (\n -> if n > 5 then Nothing else Just (fromIntegral n :: Word8, n + 1)) 1)
  print (LI.foldlChunks (\n c -> n + B.length c) 0 (L.pack [1, 2, 3]))
  putStrLn (unpackCString# "addr"#)
  closeFdWith (\(Fd n) -> print n) (Fd 7)
  print Stream
