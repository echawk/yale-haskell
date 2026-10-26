import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Short as SBS
import qualified Data.ByteString.Lazy as BL
main = do
  b <- BS.useAsCStringLen (BC.pack "hello") BS.packCStringLen
  c <- BS.useAsCString (BC.pack "abc") BS.packCString
  print (b, c, BL.toStrict (BB.toLazyByteString (BB.shortByteString (SBS.toShort (BC.pack "xy")))))
