-- createProcess closes the parent's UseHandle handles: the pipe's reader
-- sees its end (hiss's runTee)
import System.Process
import System.IO
main :: IO ()
main = do
  (rd, wr) <- createPipe
  (_,_,_,ph) <- createProcess (proc "echo" ["hello"]) { std_out = UseHandle wr, std_err = UseHandle wr }
  s <- hGetContents rd
  putStr s
  waitForProcess ph >>= print
