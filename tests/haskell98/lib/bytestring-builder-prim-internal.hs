import qualified Data.ByteString.Builder.Prim as P
import Data.ByteString.Builder.Prim.Internal
import Data.ByteString.Builder (toLazyByteString)
import qualified Data.ByteString.Lazy as L
import Data.Word (Word8)
import Foreign.Ptr (minusPtr)
import Foreign.Marshal.Array (allocaArray, peekArray)
import Foreign.Storable (pokeByteOff)

main :: IO ()
main = do
  print (size P.word32BE, sizeBound P.charUtf8, size (P.word8 P.>*< P.word16LE))
  allocaArray 8 $ \p -> do
    runF P.word32BE 0x01020304 p
    peekArray 4 p >>= print
    q <- runB P.charUtf8 '\233' p
    peekArray (q `minusPtr` p) p >>= print
  let twice = fixedPrim 2 (\w p -> pokeByteOff p 0 w >> pokeByteOff p 1 (w + 1)) :: FixedPrim Word8
  print (L.unpack (toLazyByteString (P.primFixed twice 7)))
