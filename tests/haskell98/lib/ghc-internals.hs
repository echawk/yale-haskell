-- GHC's internal constructors as pattern synonyms: W8#, I8#, IO, ST, STRef.
{-# LANGUAGE MagicHash, UnboxedTuples #-}
import GHC.Word (Word8(..), Word16(..))
import GHC.Int (Int8(..))
import GHC.IO (IO(..))
import GHC.ST (ST(..), runST)
import GHC.STRef (STRef(..))
import GHC.Exts
f :: Word8 -> Word
f (W8# w) = w + 1
main = do
  print (f 255, W16# 70000, case I8# 300 of I8# n -> n)
  r <- IO (\s -> case newMutVar# (5 :: Int) s of (# s1, v #) -> case writeMutVar# v 6 s1 of s2 -> readMutVar# v s2)
  print r
  print (runST (ST (\s -> case newByteArray# 8 s of (# s1, b #) -> case writeWordArray# b 0 77 s1 of s2 -> readWordArray# b 0 s2)))
  IO (\s -> (# s, () #)) >> putStrLn "done"
