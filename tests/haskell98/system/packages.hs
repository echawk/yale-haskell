-- An installed package (--package-db, csys/packages.mumble): its modules
-- are found, its default extensions (CPP, LambdaCase) and cpp-options
-- apply to them only, its include-dirs are searched, and its version
-- answers MIN_VERSION_greet.  A module from a -i directory is found too.
import Data.Greet
import Text.Shout
main :: IO ()
main = do
  putStrLn (greet "world")
  putStrLn greetVersion
  putStrLn (shout "quiet")
