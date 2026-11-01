import System.Posix.Directory
import Control.Concurrent
import System.Directory
import Data.List (sort)

loop :: DirStream -> IO [FilePath]
loop ds = do
  e <- readDirStream ds
  if null e then return [] else fmap (e :) (loop ds)

main :: IO ()
main = do
  createDirectoryIfMissing False "dirstream.tmp"
  writeFile "dirstream.tmp/a" ""
  writeFile "dirstream.tmp/b" ""
  ds <- openDirStream "dirstream.tmp"
  es <- loop ds
  closeDirStream ds
  print (sort (filter (`notElem` [".", ".."]) es))
  runInBoundThread (putStrLn "bound")
  removeDirectoryRecursive "dirstream.tmp"
