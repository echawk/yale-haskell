-- Data.Text.IO (text): files and handles read and written as packed text
-- in one piece (TextPrims.hi).
module Data.Text.IO (
    putStr, putStrLn, getLine, getContents, interact, readFile, writeFile,
    appendFile, hPutStr, hPutStrLn, hGetLine, hGetContents
  ) where

import Prelude hiding (putStr, putStrLn, getLine, getContents, interact,
                       readFile, writeFile, appendFile)
import qualified Prelude as P
import qualified System.IO as IO
import System.IO (Handle, IOMode(..), withFile, stdin, stdout)
import IOBase (Handle(..))
import Data.Text (pack, snoc)
import Data.Text.Rep (Text(..))
import TextPrims

putStr, putStrLn :: Text -> IO ()
putStr = hPutStr stdout
putStrLn = hPutStrLn stdout

getLine, getContents :: IO Text
getLine = hGetLine stdin
getContents = hGetContents stdin

interact :: (Text -> Text) -> IO ()
interact f = getContents >>= putStr . f

readFile :: FilePath -> IO Text
readFile f = primTextReadFile f >>= return . Text

writeFile, appendFile :: FilePath -> Text -> IO ()
writeFile f t = withFile f WriteMode (\h -> hPutStr h t)
appendFile f t = withFile f AppendMode (\h -> hPutStr h t)

hPutStr, hPutStrLn :: Handle -> Text -> IO ()
hPutStr (Handle h) (Text s) = primTextHPutStr h s
hPutStrLn h t = hPutStr h (snoc t '\n')

hGetLine, hGetContents :: Handle -> IO Text
hGetLine h = fmap pack (IO.hGetLine h)
hGetContents (Handle h) = primTextHGetContents h >>= return . Text
