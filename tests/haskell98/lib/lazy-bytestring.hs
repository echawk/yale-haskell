{-# LANGUAGE OverloadedStrings #-}
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BLC
import Data.ByteString.Builder (toLazyByteString, byteString, lazyByteString, intDec)
import Data.Char (toLower)

class FoldCase s where foldCase :: s -> s
instance FoldCase B.ByteString where foldCase = BC.map toLower
instance FoldCase BL.ByteString where foldCase = BLC.map toLower

main = do
  let l = BLC.pack "Hello, Lazy"
  print (foldCase l, foldCase (BC.pack "ABC"), BL.length l, BLC.take 5 l)
  print (BL.toStrict l, BL.fromStrict "x" <> l, BL.toStrict (BL.fromChunks ["ab", "cd"]))
  print (toLazyByteString (byteString "a" <> lazyByteString "b" <> intDec 42))
  print (BLC.lines "one\ntwo", BL.unpack (BL.pack [104, 105]), BLC.readInt "17 rest")
