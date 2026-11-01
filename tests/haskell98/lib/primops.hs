-- GHC primops (GHC.Exts, src/base/primops-runtime.lisp): Addr# literals, byte arrays, arrays, MutVar#.
{-# LANGUAGE MagicHash, UnboxedTuples #-}
import GHC.Exts
data V = O [Int] | B !Bool | N
main = do
  print (indexInt16OffAddr# "\x01\x02\xff\xff"# 1, indexCharOffAddr# "hi"# 1)
  print (runRW# (\s -> case newByteArray# 16 s of
     (# s1, mba #) -> case writeIntArray# mba 1 42 s1 of
       s2 -> case readIntArray# mba 1 s2 of (# _, v #) -> v))
  print (runRW# (\s -> case newArray# 3 (7::Int) s of (# s1, ma #) -> case writeArray# ma 2 9 s1 of s2 -> case unsafeFreezeArray# ma s2 of (# _, a #) -> (indexArray# a 0, indexArray# a 2)))
  print (runRW# (\s -> case newMutVar# "a" s of (# s1, v #) -> case writeMutVar# v "b" s1 of s2 -> case readMutVar# v s2 of (# _, x #) -> x))
  -- an element stored unevaluated is evaluated when indexed (aeson's
  -- Array of Bool values printed as Null)
  print (runRW# (\s -> case newArray# 2 N s of (# s1, ma #) -> case writeArray# ma 0 (B (not False)) s1 of s2 -> case writeArray# ma 1 (B (not True)) s2 of s3 -> case unsafeFreezeArray# ma s3 of (# _, a #) -> [case indexArray# a i of { B b -> show b; N -> "N"; O _ -> "O" } | i <- [0, 1]]))
  print (runRW# (\s -> case newArray# 1 (not True) s of (# s1, ma #) -> case unsafeFreezeArray# ma s1 of (# _, a #) -> not (indexArray# a 0)))
