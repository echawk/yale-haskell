-- The Haskell 2010 library modules (Data.List, Data.Char, Control.Monad,
-- System.IO, System.Exit, ...) with some of what 2010 added; output as GHC's.
import Data.List
import qualified Data.Char as C
import Data.Maybe (fromMaybe, mapMaybe)
import Control.Monad
import System.IO
import System.Exit
import System.Environment (getArgs)
import qualified Data.Array as A

main :: IO ()
main = do
  print (intercalate ", " ["a", "b", "c"], foldl' (+) 0 [1 .. 100000])
  print (subsequences [1, 2, 3], take 4 (permutations [1, 2, 3]))
  print (stripPrefix "foo" "foobar", isInfixOf "ob" "foobar", sort [3, 1, 2])
  print (map C.generalCategory "aA1 .λ€", C.isPunctuation '!', C.isSymbol '+')
  print (fromMaybe 0 Nothing, mapMaybe (\x -> if x > 1 then Just x else Nothing) [1, 2, 3])
  forM_ [1, 2] print
  r <- foldM (\a b -> return (a + b)) 0 [1 .. 10]
  print (r, A.listArray (0, 2) "xyz" A.! 1)
  hPutStrLn stdout "System.IO works"
  args <- getArgs
  when (null args) (putStrLn "no args")
  exitSuccess
