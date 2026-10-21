import System.Directory
import System.Posix.Files (createSymbolicLink)

main :: IO ()
main = do
  tmp <- canonicalizePath "/tmp"
  let d = tmp ++ "/yale-dir-test"
  removePathForcibly d
  createDirectoryIfMissing True (d ++ "/sub")
  writeFile (d ++ "/sub/f.txt") "abc"
  createSymbolicLink (d ++ "/sub") (d ++ "/link")
  canonicalizePath (d ++ "/link/../sub/./f.txt") >>= print . (== d ++ "/sub/f.txt")
  canonicalizePath (d ++ "/link/f.txt") >>= print . (== d ++ "/sub/f.txt")
  canonicalizePath (d ++ "/nothere/x") >>= print . (== d ++ "/nothere/x")
  pathIsSymbolicLink (d ++ "/link") >>= print
  getSymbolicLinkTarget (d ++ "/link") >>= print . (== d ++ "/sub")
  getFileSize (d ++ "/sub/f.txt") >>= print
  findFile [d, d ++ "/sub"] "f.txt" >>= print . fmap (== d ++ "/sub/f.txt")
  findFiles [d] "f.txt" >>= print
  renamePath (d ++ "/sub/f.txt") (d ++ "/sub/g.txt")
  doesFileExist (d ++ "/sub/g.txt") >>= print
  withCurrentDirectory d (makeRelativeToCurrentDirectory (d ++ "/sub/g.txt")) >>= print
  getXdgDirectory XdgConfig "agda" >>= print . (\p -> drop (length p - 5) p)
  getAppUserDataDirectory "agda" >>= print . (\p -> drop (length p - 6) p)
  print exeExtension
  removePathForcibly d
  doesDirectoryExist d >>= print
