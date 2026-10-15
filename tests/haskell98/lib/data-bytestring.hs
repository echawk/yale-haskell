-- Data.ByteString, .Char8, .UTF8 and .Builder (packed: TextPrims.hi),
-- checked against GHC 9.14's bytestring and utf8-string.
{-# LANGUAGE OverloadedStrings #-}
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Lazy as BL
import Data.Char (isDigit, toUpper)
import System.IO
import System.Directory (removeFile)

c1 :: C.ByteString
c1 = "hello world, hello bytes"

main :: IO ()
main = do
  let w = B.pack [0, 1, 127, 128, 200, 255]
  print (w, B.unpack w, B.length w, B.head w, B.last w, B.maximum w, B.minimum w)
  print (B.map (+ 1) w, B.reverse w, B.cons 9 w, B.snoc w 7, B.elem 200 w, B.notElem 3 w)
  print (B.foldl' (\a x -> a + fromIntegral x) (0 :: Int) w, B.foldr (:) [] w, B.filter even w, B.count 0 w)
  print (B.split 128 w, B.splitWith (> 100) w, B.findIndex (> 100) w, B.elemIndex 255 w, B.index w 4)
  print (B.take 2 w, B.drop 4 w, B.splitAt 3 w, B.span (< 128) w, B.breakSubstring (B.pack [128, 200]) w)
  print (B.zip (B.pack [1, 2]) (B.pack [3, 4, 5]), B.unzip [(1, 2), (3, 4)], B.replicate 3 65, B.concat [w, w])
  print (C.unpack c1, C.length c1, C.words c1, C.lines "a\nb\n\nc", C.unlines ["x", "y"], C.unwords ["x", "y"])
  print (C.map toUpper c1, C.split ',' c1, C.split ',' "", C.splitWith (== 'l') c1, C.count 'l' c1)
  print (C.isPrefixOf "hello" c1, C.isSuffixOf "bytes" c1, C.isInfixOf "world" c1, C.stripPrefix "hello " c1)
  print (C.breakSubstring "world" c1, C.breakSubstring "" c1, C.breakSubstring "zz" c1, C.spanEnd isDigit "abc123")
  print (C.readInt "-42 rest", C.readInt "x", C.readInteger "123456789012345678901 z", C.readInt "+7")
  print (C.elemIndices 'l' c1, C.elemIndexEnd 'l' c1, C.findIndices (== 'o') c1, C.indexMaybe c1 100, c1 C.!? 0)
  print (C.dropSpace "  x ", C.strip "  x  ", C.dropWhileEnd (== 's') c1, C.takeWhileEnd (/= ' ') c1)
  print (C.group "aabccc", C.inits "ab", C.tails "ab", C.intercalate ", " ["a", "b"], C.intersperse '-' "abc")
  print (C.unfoldrN 3 (\n -> Just (toEnum (n + 65), n + 1)) 0, C.zipWith (,) "ab" "cd", C.uncons "", C.unsnoc "ab")
  print (C.pack "λ→", B.unpack (C.pack "λ→"), compare c1 "hello", c1 == c1, "a" < ("b" :: C.ByteString))
  print (BL.toStrict (BL.fromStrict c1), BL.fromChunks ["a", "b"], BL.toChunks "", mempty :: C.ByteString, c1 <> "!")
  print (BB.toLazyByteString (BB.byteString "ab" <> BB.char7 'c' <> BB.intDec 42 <> BB.string7 "de"))
  C.writeFile "data-bytestring.tmp" (B.pack [0 .. 255])
  back <- B.readFile "data-bytestring.tmp"
  print (B.length back, B.unpack (B.take 5 (B.drop 250 back)), back == B.pack [0 .. 255])
  C.appendFile "data-bytestring.tmp" "tail\n"
  h <- openBinaryFile "data-bytestring.tmp" ReadMode
  rest <- B.hGetContents h
  print (B.length rest, C.takeEnd 5 rest)
  removeFile "data-bytestring.tmp"
  C.putStrLn (C.pack "plain ascii")
  B.putStr (B.pack [0xCE, 0xBB, 10])
