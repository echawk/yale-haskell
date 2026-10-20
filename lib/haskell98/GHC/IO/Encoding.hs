-- GHC.IO.Encoding (base): the text encodings (System.IO's), and the
-- locale's and file system's, UTF-8 here.
module GHC.IO.Encoding (
    TextEncoding, utf8, utf8_bom, latin1, char8, utf16, utf32, mkTextEncoding,
    textEncodingName, getLocaleEncoding, getFileSystemEncoding,
    getForeignEncoding, setLocaleEncoding, setFileSystemEncoding,
    setForeignEncoding, initLocaleEncoding
  ) where

import System.IO (TextEncoding, utf8, utf8_bom, latin1, char8, utf16, utf32, mkTextEncoding)

textEncodingName :: TextEncoding -> String
textEncodingName = show

getLocaleEncoding, getFileSystemEncoding, getForeignEncoding :: IO TextEncoding
getLocaleEncoding = return utf8
getFileSystemEncoding = return utf8
getForeignEncoding = return utf8

setLocaleEncoding, setFileSystemEncoding, setForeignEncoding :: TextEncoding -> IO ()
setLocaleEncoding _ = return ()
setFileSystemEncoding _ = return ()
setForeignEncoding _ = return ()

initLocaleEncoding :: TextEncoding
initLocaleEncoding = utf8
