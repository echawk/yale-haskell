-- Data.Text processing: building, splitting, searching, case mapping,
-- replacing and file I/O over a ~6 MB text.
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.List (foldl')
import System.Directory (removeFile)

line :: Int -> T.Text
line i = T.pack ("record " ++ show i ++ ": the quick brown fox, jumps over " ++
                 show (i * 7 `mod` 1000) ++ " lazy dogs; status=" ++
                 (if even i then "ok" else "fail"))

main :: IO ()
main = do
  let doc = T.unlines (map line [1 .. 60000])
  TIO.writeFile "textproc.tmp" doc
  t <- TIO.readFile "textproc.tmp"
  removeFile "textproc.tmp"
  let ls = T.lines t
      ws = concatMap T.words ls
  print (T.length t, length ls, length ws)
  print (length (filter (T.isInfixOf (T.pack "fail")) ls))
  print (T.count (T.pack "fox") t, T.length (T.toUpper t))
  let fields = map (T.splitOn (T.pack ";")) ls
  print (foldl' (\n fs -> n + length fs) 0 fields)
  let r = T.replace (T.pack "lazy") (T.pack "sleepy") t
  print (T.length r, T.take 40 (T.strip (head (T.lines r))))
  print (sum [ T.length (T.filter (== 'o') l) | l <- ls ])
  print (length (filter (\l -> T.pack "ok" `T.isSuffixOf` l) ls))
