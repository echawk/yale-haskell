-- module Prelude re-exports base's Prelude (with --modern-prelude) but not
-- Ix; Foldable(..) re-exports the methods in scope; hiding a name hides
-- it wherever it comes from (here foldl, null: the Prelude's and
-- Foldable's).
import ShimPrelude hiding (foldl, null)
import Prelude ()

foldl :: Int -> Int
foldl = (+ 1)

null :: Bool
null = True

index :: Int
index = 7

main :: IO ()
main = print (foldMap (: []) (Just 'x'), length [1, 2, 3 :: Int], foldl 1, null, index, mempty :: String, 'a' <$ Just ())
