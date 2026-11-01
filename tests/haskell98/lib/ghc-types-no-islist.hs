import GHC.Types
import GHC.Prim
import Data.Foldable (toList)

main :: IO ()
main = print (toList (Just (1 :: Int)))
