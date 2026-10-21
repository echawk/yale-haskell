-- System.Posix.Temp (unix), a subset: mkstemp.
module System.Posix.Temp (mkstemp) where

import PosixPrims
import System.IO (Handle)
import System.Posix.Types (Fd(Fd))
import System.Posix.IO (fdToHandle)

-- | A new file named the prefix and six more characters, open for
-- reading and writing.
mkstemp :: String -> IO (FilePath, Handle)
mkstemp prefix = do
  r <- primPosixMkstemp prefix
  h <- fdToHandle (Fd (fromIntegral (primMkstempFd r)))
  return (primMkstempName r, h)
