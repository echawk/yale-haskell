-- base's instances for Data.Semigroup's Arg, Min, Max, First and Last
import Data.Semigroup
import Data.Bifunctor
import Data.Bifoldable
import Data.Bitraversable
main :: IO ()
main = do
  print (fmap (+1) (Arg 'x' 1), sum (Arg 'y' 3), bimap succ show (Arg 'a' 2))
  print (bifoldMap show show (Arg 1 2))
  print (bitraverse Just Just (Arg 1 'c'))
  print (traverse (\x -> [x, x+1]) (Min 3), sum (Max 4), Min (+1) <*> Min 2, getLast (Last 1 >>= \x -> Last (x * 10)))
