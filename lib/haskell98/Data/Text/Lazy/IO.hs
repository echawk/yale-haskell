-- Data.Text.Lazy.IO (text): Data.Text.IO at the lazy Text type.
module Data.Text.Lazy.IO (
    putStr, putStrLn, getLine, getContents, interact, readFile, writeFile,
    appendFile, hPutStr, hPutStrLn, hGetLine, hGetContents
  ) where

import Prelude hiding (putStr, putStrLn, getLine, getContents, interact,
                       readFile, writeFile, appendFile)
import System.IO (Handle)
import qualified Data.Text.IO as S
import Data.Text.Lazy (Text, fromStrict, toStrict)

putStr, putStrLn :: Text -> IO ()
putStr = S.putStr . toStrict
putStrLn = S.putStrLn . toStrict

getLine, getContents :: IO Text
getLine = fmap fromStrict S.getLine
getContents = fmap fromStrict S.getContents

interact :: (Text -> Text) -> IO ()
interact f = S.interact (toStrict . f . fromStrict)

readFile :: FilePath -> IO Text
readFile f = fmap fromStrict (S.readFile f)

writeFile, appendFile :: FilePath -> Text -> IO ()
writeFile f = S.writeFile f . toStrict
appendFile f = S.appendFile f . toStrict

hPutStr, hPutStrLn :: Handle -> Text -> IO ()
hPutStr h = S.hPutStr h . toStrict
hPutStrLn h = S.hPutStrLn h . toStrict

hGetLine, hGetContents :: Handle -> IO Text
hGetLine h = fmap fromStrict (S.hGetLine h)
hGetContents h = fmap fromStrict (S.hGetContents h)
