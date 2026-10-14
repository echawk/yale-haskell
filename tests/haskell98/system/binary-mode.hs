-- hSetBinaryMode on file handles: the rest of the file is read or
-- written as bytes (Latin-1) from the current position.
import System.Directory (removeFile)
import System.IO
main = do
  writeFile "bin-test.txt" "h\233llo\n"
  h <- openFile "bin-test.txt" ReadMode
  c <- hGetChar h
  hSetBinaryMode h True
  s <- hGetContents h
  print (c, map fromEnum s)
  w <- openFile "bin-test.out" WriteMode
  hPutStr w "\955"
  hSetBinaryMode w True
  hPutStr w "\200\n"
  hClose w
  b <- openBinaryFile "bin-test.out" ReadMode
  t <- hGetContents b
  print (map fromEnum t)
  mapM_ removeFile ["bin-test.txt", "bin-test.out"]
