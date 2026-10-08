-- Directory: creating, listing, renaming and removing files and
-- directories, permissions, modification times and the current
-- directory, under a scratch directory in /tmp.
module Main where
import Dialogue (thenIO, thenIO_, returnIO)

import Prelude hiding (stdin, stdout, stderr)
import IO
import Directory
import Time

base :: String
base = "/tmp/yale-haskell-directory-test"

say :: String -> IO ()
say s = hPutStrLn stdout s

-- Run an action that should fail, and say how.
failing :: String -> IO a -> IO ()
failing what m =
  catch (m `thenIO_` say (what ++ ": no error"))
        (\e -> say (what ++ ": " ++ kind e))

kind :: IOError -> String
kind e | isAlreadyExistsError e = "alreadyExists"
       | isDoesNotExistError e  = "doesNotExist"
       | isPermissionError e    = "permission"
       | isIllegalOperation e   = "illegalOperation"
       | otherwise              = "other error"

ignoring :: IO () -> IO ()
ignoring m = catch m (\_ -> returnIO ())

-- (Not the Prelude's <= on strings: the 1.2 Prelude's derived Ord on
-- lists puts [] after non-empty lists.)
sort :: [String] -> [String]
sort = foldr insert []
  where insert x [] = [x]
        insert x (y:ys) | before x y = x : y : ys
                        | otherwise  = y : insert x ys
        before [] _          = True
        before _ []          = False
        before (a:as) (b:bs) = a < b || (a == b && before as bs)

endsWith :: String -> String -> Bool
endsWith suffix s = reverse suffix == take (length suffix) (reverse s)

listing :: String -> IO ()
listing dir = getDirectoryContents dir `thenIO` \names ->
              say ("contents: " ++ unwords (sort names))

writeTo :: String -> String -> IO ()
writeTo name s = openFile name WriteMode `thenIO` \h ->
                 hPutStr h s `thenIO_` hClose h

perms :: Permissions -> String
perms p = [ if f p then c else '-'
          | (f, c) <- [(readable, 'r'), (writable, 'w'),
                       (executable, 'x'), (searchable, 's')] ]

cleanUp :: IO ()
cleanUp = ignoring (removeFile (base ++ "/a.txt")) `thenIO_`
          ignoring (removeFile (base ++ "/b.txt")) `thenIO_`
          ignoring (removeDirectory (base ++ "/sub")) `thenIO_`
          ignoring (removeDirectory (base ++ "/sub2")) `thenIO_`
          ignoring (removeDirectory base)

main :: IO ()
main =
  cleanUp `thenIO_`
  getClockTime `thenIO` \start ->
  createDirectory base `thenIO_`
  doesDirectoryExist base `thenIO` \d ->
  doesFileExist base `thenIO` \f ->
  say ("created: directory " ++ show d ++ ", file " ++ show f) `thenIO_`
  failing "create again" (createDirectory base) `thenIO_`
  failing "create in missing parent" (createDirectory (base ++ "/x/y")) `thenIO_`
  writeTo (base ++ "/a.txt") "hello\n" `thenIO_`
  doesFileExist (base ++ "/a.txt") `thenIO` \fa ->
  doesDirectoryExist (base ++ "/a.txt") `thenIO` \da ->
  say ("a.txt: file " ++ show fa ++ ", directory " ++ show da) `thenIO_`
  listing base `thenIO_`
  renameFile (base ++ "/a.txt") (base ++ "/b.txt") `thenIO_`
  listing base `thenIO_`
  failing "rename missing file" (renameFile (base ++ "/a.txt") (base ++ "/c.txt")) `thenIO_`
  createDirectory (base ++ "/sub") `thenIO_`
  failing "renameFile on a directory" (renameFile (base ++ "/sub") (base ++ "/s")) `thenIO_`
  failing "renameDirectory on a file" (renameDirectory (base ++ "/b.txt") (base ++ "/s")) `thenIO_`
  renameDirectory (base ++ "/sub") (base ++ "/sub2") `thenIO_`
  listing base `thenIO_`
  getPermissions (base ++ "/b.txt") `thenIO` \pf ->
  getPermissions (base ++ "/sub2") `thenIO` \pd ->
  say ("permissions: file " ++ perms pf ++ ", directory " ++ perms pd) `thenIO_`
  setPermissions (base ++ "/b.txt") (Permissions True False True False) `thenIO_`
  getPermissions (base ++ "/b.txt") `thenIO` \pf2 ->
  say ("after setPermissions: " ++ perms pf2) `thenIO_`
  failing "open read-only file for writing" (openFile (base ++ "/b.txt") AppendMode) `thenIO_`
  setPermissions (base ++ "/b.txt") pf `thenIO_`
  getPermissions (base ++ "/b.txt") `thenIO` \pf3 ->
  say ("restored: " ++ perms pf3) `thenIO_`
  failing "permissions of missing file" (getPermissions (base ++ "/nope")) `thenIO_`
  getModificationTime (base ++ "/b.txt") `thenIO` \mtime ->
  getClockTime `thenIO` \now ->
  say ("modification time plausible: "
       ++ show (tdSec (diffClockTimes mtime start) >= -2 &&
                tdSec (diffClockTimes now mtime) >= -2)) `thenIO_`
  failing "modification time of missing file" (getModificationTime (base ++ "/nope")) `thenIO_`
  getCurrentDirectory `thenIO` \cwd ->
  setCurrentDirectory base `thenIO_`
  getCurrentDirectory `thenIO` \inside ->
  say ("cd: ends in test directory "
       ++ show ("/yale-haskell-directory-test" `endsWith` inside)) `thenIO_`
  doesFileExist "b.txt" `thenIO` \rel ->
  openFile "b.txt" ReadMode `thenIO` \h ->
  hGetLine h `thenIO` \l ->
  hClose h `thenIO_`
  say ("relative names: " ++ show rel ++ " " ++ l) `thenIO_`
  setCurrentDirectory cwd `thenIO_`
  getCurrentDirectory `thenIO` \back ->
  say ("cd back: " ++ show (back == cwd)) `thenIO_`
  failing "cd to missing directory" (setCurrentDirectory (base ++ "/nope")) `thenIO_`
  failing "remove non-empty directory" (removeDirectory base) `thenIO_`
  failing "removeFile on a directory" (removeFile (base ++ "/sub2")) `thenIO_`
  removeFile (base ++ "/b.txt") `thenIO_`
  failing "remove missing file" (removeFile (base ++ "/b.txt")) `thenIO_`
  removeDirectory (base ++ "/sub2") `thenIO_`
  listing base `thenIO_`
  removeDirectory base `thenIO_`
  doesDirectoryExist base `thenIO` \gone ->
  say ("removed: " ++ show (not gone)) `thenIO_`
  failing "list missing directory" (getDirectoryContents base)
