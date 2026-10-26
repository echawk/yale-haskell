-- Lines that threads write to one handle stay whole: putStrLn is one
-- write, and a handle is used by one thread at a time.
import Control.Concurrent
import Control.Monad
import System.IO
import System.Directory (getTemporaryDirectory, removeFile)
main = do
  tmp <- getTemporaryDirectory
  let file = tmp ++ "/yale-threads-output.tmp"
  h <- openFile file WriteMode
  hSetBuffering h LineBuffering
  ds <- forM [1 .. 8 :: Int] $ \i -> do
    d <- newEmptyMVar
    _ <- forkIO (forM_ [1 .. 300 :: Int] (\j -> hPutStrLn h (show i ++ " line " ++ show j)) >> putMVar d ())
    return d
  mapM_ takeMVar ds
  hClose h
  ls <- fmap lines (readFile file)
  print (length ls, length (filter good ls))
  removeFile file
  where good l = case words l of
                   [a, "line", b] -> all (`elem` "0123456789") (a ++ b)
                   _ -> False
