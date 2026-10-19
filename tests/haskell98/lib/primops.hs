-- GHC primops (GHC.Exts, src/base/primops-runtime.lisp): Addr# literals, byte arrays, arrays, MutVar#.
{-# LANGUAGE MagicHash, UnboxedTuples #-}
import GHC.Exts
main = do
  print (indexInt16OffAddr# "\x01\x02\xff\xff"# 1, indexCharOffAddr# "hi"# 1)
  print (runRW# (\s -> case newByteArray# 16 s of
     (# s1, mba #) -> case writeIntArray# mba 1 42 s1 of
       s2 -> case readIntArray# mba 1 s2 of (# _, v #) -> v))
  print (runRW# (\s -> case newArray# 3 (7::Int) s of (# s1, ma #) -> case writeArray# ma 2 9 s1 of s2 -> case unsafeFreezeArray# ma s2 of (# _, a #) -> (indexArray# a 0, indexArray# a 2)))
  print (runRW# (\s -> case newMutVar# "a" s of (# s1, v #) -> case writeMutVar# v "b" s1 of s2 -> case readMutVar# v s2 of (# _, x #) -> x))
