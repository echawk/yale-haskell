-- Data.ByteString.Builder.Extra (bytestring): Yale Haskell's Builder has
-- no buffers, so the chunk and copy/insert controls are the plain
-- builders, and runBuilder writes the whole output in buffer-sized pieces.
module Data.ByteString.Builder.Extra (
    AllocationStrategy, toLazyByteStringWith, safeStrategy,
    untrimmedStrategy, smallChunkSize, defaultChunkSize,
    byteStringCopy, byteStringInsert, byteStringThreshold,
    lazyByteStringCopy, lazyByteStringInsert, lazyByteStringThreshold,
    flush, BufferWriter, Next(..), runBuilder,
    intHost, int16Host, int32Host, int64Host,
    wordHost, word16Host, word32Host, word64Host, floatHost, doubleHost
  ) where

import PreludeModern (Monoid(mempty))
import Data.ByteString.Builder
import qualified Data.ByteString as S
import qualified Data.ByteString.Lazy as L
import Data.Int
import Data.Word
import Foreign.Ptr (Ptr, castPtr)
import Foreign.Storable (Storable, poke, peek)
import Foreign.Marshal.Array (pokeArray)
import Foreign.Marshal.Alloc (alloca)
import System.IO.Unsafe (unsafePerformIO)

data AllocationStrategy = AllocationStrategy Int Int

safeStrategy, untrimmedStrategy :: Int -> Int -> AllocationStrategy
safeStrategy = AllocationStrategy
untrimmedStrategy = AllocationStrategy

smallChunkSize, defaultChunkSize :: Int
smallChunkSize = 4096 - 16
defaultChunkSize = 32768 - 16

toLazyByteStringWith :: AllocationStrategy -> L.ByteString -> Builder
                     -> L.ByteString
toLazyByteStringWith _ k b = toLazyByteString b `L.append` k

byteStringCopy, byteStringInsert :: S.ByteString -> Builder
byteStringCopy = byteString
byteStringInsert = byteString

byteStringThreshold :: Int -> S.ByteString -> Builder
byteStringThreshold _ = byteString

lazyByteStringCopy, lazyByteStringInsert :: L.ByteString -> Builder
lazyByteStringCopy = lazyByteString
lazyByteStringInsert = lazyByteString

lazyByteStringThreshold :: Int -> L.ByteString -> Builder
lazyByteStringThreshold _ = lazyByteString

flush :: Builder
flush = mempty

type BufferWriter = Ptr Word8 -> Int -> IO (Int, Next)

data Next = Done
          | More !Int BufferWriter
          | Chunk !S.ByteString BufferWriter

runBuilder :: Builder -> BufferWriter
runBuilder b = writeBytes (L.unpack (toLazyByteString b))

writeBytes :: [Word8] -> BufferWriter
writeBytes ws p n =
  case splitAt n ws of
    (now, []) -> do pokeArray p now; return (length now, Done)
    (now, rest) -> do pokeArray p now; return (n, More 1 (writeBytes rest))

-- Host byte order: little-endian (x86-64, AArch64); Int and Word are 64 bits.
intHost :: Int -> Builder
intHost = int64LE . fromIntegral
int16Host :: Int16 -> Builder
int16Host = int16LE
int32Host :: Int32 -> Builder
int32Host = int32LE
int64Host :: Int64 -> Builder
int64Host = int64LE
wordHost :: Word -> Builder
wordHost = word64LE . fromIntegral
word16Host :: Word16 -> Builder
word16Host = word16LE
word32Host :: Word32 -> Builder
word32Host = word32LE
word64Host :: Word64 -> Builder
word64Host = word64LE

floatHost :: Float -> Builder
floatHost x = word32LE (unsafePerformIO (alloca (\p -> do
  poke p x; peekAs (castPtr p))))
doubleHost :: Double -> Builder
doubleHost x = word64LE (unsafePerformIO (alloca (\p -> do
  poke p x; peekAs (castPtr p))))

peekAs :: Storable a => Ptr a -> IO a
peekAs = peek
