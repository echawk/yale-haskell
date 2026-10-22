import System.IO
import System.Directory (getTemporaryDirectory)
import GHC.IO.Handle (hDuplicate, hDuplicateTo)
main = do
  d <- getTemporaryDirectory
  let f = d ++ "/yale-handle-duplicate.txt"
  h <- openFile f WriteMode
  out2 <- hDuplicate stdout
  hDuplicateTo h stdout
  putStrLn "captured"
  hDuplicateTo out2 stdout
  hClose h
  s <- readFile f
  putStr ("got: " ++ s)
