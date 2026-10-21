import Data.Word (Word8)
import Data.ByteString.Builder (Builder, toLazyByteString, string7)
import Data.ByteString.Builder.Extra
import qualified Data.ByteString.Lazy as L
import Foreign.Marshal.Array (allocaArray, peekArray)

drain :: BufferWriter -> IO [[Word8]]
drain w = allocaArray 4 $ \p -> do
  (n, next) <- w p 4
  bs <- peekArray n p
  case next of
    Done -> return [bs]
    More _ w' -> fmap (bs :) (drain w')
    Chunk _ w' -> fmap (bs :) (drain w')

main :: IO ()
main = do
  print (L.unpack (toLazyByteString (word16Host 258 <> int32Host (-2) <> flush)))
  print (L.unpack (toLazyByteStringWith (safeStrategy 4 8) (L.pack [9]) (doubleHost 1)))
  drain (runBuilder (string7 "hello, world")) >>= print
