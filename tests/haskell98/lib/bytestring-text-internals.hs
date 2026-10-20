{-# LANGUAGE PatternSynonyms #-}
module Main (main) where
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import Data.ByteString.Internal (ByteString(BS), unsafeCreate)
import qualified Data.ByteString.Short.Internal as SBS
import qualified Data.Text as T
import Data.Text.Internal (Text(..))
import qualified Data.Text.Array as A
import Foreign.ForeignPtr (withForeignPtr)
import Foreign.Storable (peekByteOff, pokeByteOff)
import Data.Word (Word8)
import System.IO.Unsafe (unsafePerformIO)

firstByte :: ByteString -> Word8
firstByte (BS fp n) | n > 0 = unsafePerformIO (withForeignPtr fp (\p -> peekByteOff p 0))
firstByte _ = 0

main :: IO ()
main = do
  let b = BC.pack "hello"
  print (firstByte b, case b of BS _ n -> n)
  print (unsafeCreate 3 (\p -> mapM_ (\i -> pokeByteOff p i (65 + fromIntegral i :: Word8)) [0 .. 2]))
  case SBS.toShort b of SBS.SBS arr -> print (BS.unpack (SBS.fromShort (SBS.SBS arr)))
  let t = T.pack "héllo"
  case t of Text arr off len -> print (off, len, map (A.unsafeIndex arr) [0 .. len - 1], Text arr 3 2)
