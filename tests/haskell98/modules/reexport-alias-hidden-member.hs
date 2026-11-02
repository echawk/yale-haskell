import Prelude ()
import ReexportAliasCompat
main :: IO ()
main = print (length [1, 2, 3 :: Int], twice 4, sum (Just (5 :: Int)), fromMaybe 0 Nothing)
