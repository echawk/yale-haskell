{-# LANGUAGE MagicHash #-}
import GHC.CString
main = do
  putStrLn (unpackCString# "hello"#)
  print (cstringLength# "abc"#, unpackCStringUtf8# "caf\xc3\xa9"#, unpackNBytes# "xyzw"# 2)
