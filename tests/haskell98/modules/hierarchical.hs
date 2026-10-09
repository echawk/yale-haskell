-- Hierarchical module names (Haskell 2010): Hier.Util is Hier/Util.hs
-- next to this file, and it finds its sibling Hier.Text from the root.
import Hier.Util
import qualified Hier.Text as T

main :: IO ()
main = do
  print (double 21)
  putStrLn greeting
  putStrLn T.greeting
