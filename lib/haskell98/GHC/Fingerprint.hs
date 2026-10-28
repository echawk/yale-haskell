-- GHC.Fingerprint (base): MD5 fingerprints, as GHC's (the digest's two
-- halves as big-endian Word64s), so that GHC's interface hashes agree.
module GHC.Fingerprint (
    Fingerprint(..), fingerprint0, fingerprintData, fingerprintString,
    fingerprintFingerprints, getFileHash
  ) where

import Data.Bits ((.&.), (.|.), complement, rotateL, shiftL, shiftR, xor)
import Data.Char (ord)
import Data.List (foldl')
import Data.Word (Word8, Word32, Word64)
import Foreign.Marshal.Array (peekArray)
import Foreign.Ptr (Ptr)
import GHC.Fingerprint.Type (Fingerprint(..))
import qualified Data.ByteString as B

fingerprint0 :: Fingerprint
fingerprint0 = Fingerprint 0 0

fingerprintData :: Ptr Word8 -> Int -> IO Fingerprint
fingerprintData p n = fmap fingerprintBytes (peekArray n p)

-- each character as four bytes, big-endian
fingerprintString :: String -> Fingerprint
fingerprintString = fingerprintBytes . concatMap bytes
  where bytes c = let w = ord c
                  in [fromIntegral (w `shiftR` 24), fromIntegral (w `shiftR` 16),
                      fromIntegral (w `shiftR` 8), fromIntegral w]

-- the fingerprints as stored (Storable: each half big-endian)
fingerprintFingerprints :: [Fingerprint] -> Fingerprint
fingerprintFingerprints fs = fingerprintBytes (concat [be64 a ++ be64 b | Fingerprint a b <- fs])

getFileHash :: FilePath -> IO Fingerprint
getFileHash path = fmap (fingerprintBytes . B.unpack) (B.readFile path)

be64 :: Word64 -> [Word8]
be64 w = [fromIntegral (w `shiftR` s) | s <- [56, 48 .. 0]]

fingerprintBytes :: [Word8] -> Fingerprint
fingerprintBytes bs = Fingerprint (fromBE (take 8 digest)) (fromBE (drop 8 digest))
  where digest = md5 bs
        fromBE = foldl' (\ acc b -> acc `shiftL` 8 .|. fromIntegral b) 0

-- RFC 1321
md5 :: [Word8] -> [Word8]
md5 msg = concatMap le32 [a, b, c, d]
  where
    len = length msg
    padded = msg ++ [0x80] ++ replicate ((55 - len) `mod` 64) 0 ++
             [fromIntegral ((fromIntegral len * 8 :: Word64) `shiftR` s) | s <- [0, 8 .. 56]]
    (a, b, c, d) = foldl' block (0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476) (chunks padded)
    chunks [] = []
    chunks xs = let (h, t) = splitAt 64 xs in words32 h : chunks t
    words32 [] = []
    words32 (b0 : b1 : b2 : b3 : r) =
      (fromIntegral b0 .|. fromIntegral b1 `shiftL` 8 .|. fromIntegral b2 `shiftL` 16 .|.
       fromIntegral b3 `shiftL` 24) : words32 r
    words32 _ = error "md5"
    le32 w = [fromIntegral (w `shiftR` s) | s <- [0, 8, 16, 24]]

block :: (Word32, Word32, Word32, Word32) -> [Word32] -> (Word32, Word32, Word32, Word32)
block (a0, b0, c0, d0) m = a0 `seq` b0 `seq` c0 `seq` d0 `seq`
    (a0 + a', b0 + b', c0 + c', d0 + d')
  where
    (a', b', c', d') = foldl' step (a0, b0, c0, d0) (zip3 [0 .. 63] shifts sines)
    step (a, b, c, d) (i, s, k) = a `seq` b `seq` c `seq` d `seq`
      let (f, g) | i < 16 = ((b .&. c) .|. (complement b .&. d), i)
                 | i < 32 = ((d .&. b) .|. (complement d .&. c), (5 * i + 1) `mod` 16)
                 | i < 48 = (b `xor` c `xor` d, (3 * i + 5) `mod` 16)
                 | otherwise = (c `xor` (b .|. complement d), (7 * i) `mod` 16)
          f' = f + a + k + (m !! g)
      in (d, b + (f' `rotateL` s), b, c)

shifts :: [Int]
shifts = concatMap (concat . replicate 4) [[7, 12, 17, 22], [5, 9, 14, 20], [4, 11, 16, 23], [6, 10, 15, 21]]

sines :: [Word32]
sines = [floor (abs (sin (fromIntegral i :: Double)) * 4294967296) | i <- [1 .. 64 :: Int]]
