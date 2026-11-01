import System.Directory
import Data.Time.Clock

main :: IO ()
main = do
  writeFile "dirmore.tmp" "x"
  copyFileWithMetadata "dirmore.tmp" "dirmore2.tmp"
  t <- getModificationTime "dirmore2.tmp"
  setModificationTime "dirmore.tmp" t
  let p = setOwnerReadable True emptyPermissions
  print (readable p, writable p)
  r <- findFileWith (\_ -> return True) ["."] "dirmore.tmp"
  print r
  _ <- getAccessTime "dirmore.tmp"
  removeFile "dirmore.tmp"
  removeFile "dirmore2.tmp"
