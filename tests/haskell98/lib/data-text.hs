-- Data.Text's API (packed: TextPrims.hi), checked against GHC 9.14's text.
{-# LANGUAGE OverloadedStrings #-}
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Char (isDigit, isUpper, toUpper)
import System.IO
import System.Directory (removeFile)

t1, t2, uni, sp :: T.Text
t1 = "hello world, hello text"
t2 = ""
uni = "λx → ünïcödé ⊕ 日本"
sp = "  \t padded \n "

main :: IO ()
main = do
  print (T.pack "abc", T.unpack t1, T.empty, T.singleton 'q', T.length uni)
  print (T.cons 'x' t1, T.snoc t2 'y', T.append t1 uni, t1 <> "!", mempty :: T.Text)
  print (T.uncons t1, T.uncons t2, T.unsnoc uni, T.unsnoc t2)
  print (T.head uni, T.last uni, T.tail "ab", T.init "ab", T.null t2, T.null t1)
  print (T.compareLength t1 5, T.compareLength t1 100, compare t1 uni, t1 == t1, t1 < t2, uni > t1)
  print (T.map toUpper uni, T.intercalate ", " ["a", "b", "c"], T.intersperse '-' "abc")
  print (T.transpose ["abc", "de"], T.reverse uni, T.replace "hello" "bye" t1, T.replace "x" "y" t2)
  print (T.toUpper uni, T.toLower "ÀBC", T.toCaseFold "ABC", T.toTitle "the quick fox")
  print (T.justifyLeft 8 '.' "ab", T.justifyRight 8 '.' "ab", T.center 9 '*' "ab", T.center 1 '*' "abc")
  print (T.foldl (flip (:)) [] "abc", T.foldl' (\n c -> n * 10 + fromEnum c - 48) 0 "1234", T.foldr (:) [] "xyz")
  print (T.foldl1 max "hello", T.foldr1 min "hello", T.concat ["a", "", "bc"], T.concatMap (T.replicate 2 . T.singleton) "ab")
  print (T.any isDigit t1, T.all isDigit "123", T.all isDigit t2, T.any isDigit t2, T.maximum uni, T.minimum t1)
  print (T.scanl max 'a' "cab", T.scanl1 max "cab", T.scanr max 'a' "cab", T.scanr1 max "cab")
  print (T.mapAccumL (\a c -> (a + 1, toUpper c)) 0 "abc", T.mapAccumR (\a c -> (a + 1, c)) 0 "abc")
  print (T.replicate 3 "ab", T.replicate 0 "ab", T.unfoldr (\n -> if n > 3 then Nothing else Just (toEnum (n + 48), n + 1)) 0)
  print (T.unfoldrN 2 (\n -> Just ('z', n)) 0, T.take 3 uni, T.take 100 t1, T.take (-1) t1, T.takeEnd 4 uni, T.drop 20 t1)
  print (T.drop (-2) "ab", T.dropEnd 3 t1, T.dropEnd 100 t1, T.takeEnd 0 t1, T.takeEnd 100 "ab")
  print (T.takeWhile (/= ' ') t1, T.dropWhile (/= ' ') t1, T.takeWhileEnd (/= ' ') t1, T.dropWhileEnd (/= ' ') t1)
  print (T.dropAround (== '*') "**a*b**", T.filter isUpper "AbCd", T.strip sp, T.stripStart sp, T.stripEnd sp, T.strip "   ")
  print (T.splitAt 5 t1, T.splitAt 100 t2, T.breakOn ", " t1, T.breakOn "zz" t1, T.breakOnEnd "hello" t1)
  print (T.breakOnAll "hello" t1, T.break (== ',') t1, T.span (/= 'w') t1)
  r <- T.spanM (\c -> return (c /= 'o')) t1
  print (r, T.group "aabccc", T.groupBy (\a b -> isDigit a == isDigit b) "12ab3")
  print (T.inits "abc", T.tails "abc", T.splitOn "," "a,b,,c,", T.splitOn "ab" "ab", T.split (== ',') "a,,b")
  print (T.chunksOf 3 "abcdefgh", T.chunksOf 3 "", T.lines "a\n\nb\n", T.lines "a\nb", T.words sp, T.words "  a b  ")
  print (T.unlines ["a", "b"], T.unwords ["a", "b"], T.isPrefixOf "hel" t1, T.isSuffixOf "text" t1, T.isInfixOf "o w" t1)
  print (T.isPrefixOf "" t2, T.isInfixOf "zz" t1, T.stripPrefix "hello " t1, T.stripPrefix "x" t1, T.stripSuffix "text" t1)
  print (T.commonPrefixes "foobar" "fooquux", T.commonPrefixes "x" "y", T.find isDigit "ab3c", T.find isDigit "abc")
  print (T.elem 'w' t1, T.elem '?' t1, T.partition isDigit "a1b2", T.index uni 1, T.findIndex (== 'o') t1, T.findIndex (== '?') t1)
  print (T.count "hello" t1, T.count "aa" "aaaaa", T.zip "abc" "de", T.zipWith max "abc" "bab", T.copy t1)
  print (read "\"read me\"" :: T.Text, show uni, T.words "x\160y z")
  TIO.writeFile "data-text.tmp" (T.unlines [uni, t1])
  TIO.appendFile "data-text.tmp" "more\n"
  back <- TIO.readFile "data-text.tmp"
  print back
  h <- openFile "data-text.tmp" ReadMode
  l1 <- TIO.hGetLine h
  rest <- TIO.hGetContents h
  print (l1, rest)
  hClose h
  removeFile "data-text.tmp"
  TIO.putStrLn uni
  TIO.putStr "no newline"
  TIO.hPutStrLn stdout ""
