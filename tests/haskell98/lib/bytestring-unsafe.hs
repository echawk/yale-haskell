{-# LANGUAGE MagicHash #-}
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Unsafe as BU
main = do
  let b = BC.pack "hello"
  print (BU.unsafeHead b, BU.unsafeIndex b 4, BU.unsafeTake 2 b, BU.unsafeDrop 3 b, BU.unsafeLast b)
  c <- BU.unsafePackAddressLen 3 "xyzw"#
  d <- BU.unsafeUseAsCStringLen b BU.unsafePackCStringLen
  print (c, d)
