module Main (main) where
import Data.Monoid
import Data.Semigroup (Max(..))
import Data.Functor.Identity
import Data.Ord (Down(..))
main :: IO ()
main = print (getSum (1 + 2 * 3), getProduct (Product 2 + 5), getMax (Max 3 - 1), runIdentity (Identity 4 * 2), getDown (Down 1 + 1 :: Down Int))
