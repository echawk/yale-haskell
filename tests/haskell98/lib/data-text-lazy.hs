-- Data.Text.Lazy is its own type (instances for both), over the packed Text.
{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.Lazy as L
class C a where c :: a -> String
instance C T.Text where c t = "strict " ++ T.unpack t
instance C L.Text where c t = "lazy " ++ L.unpack t
main = do
  putStrLn (c (T.pack "a") ++ ", " ++ c (L.pack "b"))
  print (L.length "hello", L.take 2 "hello", L.splitAt 3 "hello", L.words "a b  c", L.toStrict (L.fromChunks ["x","y"]))
  print (L.toChunks "", L.count "l" "hello", L.replicate 2 "ab", L.filter (/= 'l') "hello")
