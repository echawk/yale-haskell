import Data.Foldable (Foldable(..))
import Data.Monoid (Sum(..))
newtype Box a = Box a
instance Foldable Box where
  fold (Box a) = a
  foldMap f (Box a) = f a
fold3 :: Int -> Int
fold3 = (* 3)
main = do
  print (getSum (fold [Sum 1, Sum 2 :: Sum Int]), fold (Box "x"), getSum (foldMap' Sum [1..10 :: Int]))
