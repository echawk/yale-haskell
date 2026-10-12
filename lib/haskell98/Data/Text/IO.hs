-- Data.Text.IO (text)
module Data.Text.IO (
    putStr, putStrLn, getLine, getContents, interact, readFile, writeFile,
    appendFile, hPutStr, hPutStrLn, hGetLine, hGetContents
  ) where

import Prelude hiding (putStr, putStrLn, getLine, getContents, interact,
                       readFile, writeFile, appendFile)
import qualified Prelude as P
import qualified System.IO as IO
import System.IO (Handle)
import Data.Text (Text, pack, unpack)

putStr, putStrLn :: Text -> IO ()
putStr = P.putStr . unpack
putStrLn = P.putStrLn . unpack

getLine, getContents :: IO Text
getLine = fmap pack P.getLine
getContents = fmap pack P.getContents

interact :: (Text -> Text) -> IO ()
interact f = P.interact (unpack . f . pack)

readFile :: FilePath -> IO Text
readFile f = fmap pack (P.readFile f)

writeFile, appendFile :: FilePath -> Text -> IO ()
writeFile f = P.writeFile f . unpack
appendFile f = P.appendFile f . unpack

hPutStr, hPutStrLn :: Handle -> Text -> IO ()
hPutStr h = IO.hPutStr h . unpack
hPutStrLn h = IO.hPutStrLn h . unpack

hGetLine, hGetContents :: Handle -> IO Text
hGetLine h = fmap pack (IO.hGetLine h)
hGetContents h = fmap pack (IO.hGetContents h)
