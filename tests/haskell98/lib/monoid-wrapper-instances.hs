import Data.Monoid
import Data.Functor.Contravariant
import Data.Functor.Reverse
main = do
  print (fmap (+1) (Dual 1), (+) <$> Sum 1 <*> Sum 2, Product 3 >>= \x -> Product (x * 2))
  print (fmap show (First (Just 1)), getLast (Last (Just 1) >>= \x -> Last (Just (x + 1))))
  print (getPredicate (getReverse (contramap length (Reverse (Predicate even)))) "ab")
