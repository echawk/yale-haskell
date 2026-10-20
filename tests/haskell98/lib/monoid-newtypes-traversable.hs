import Data.Monoid
import Data.Foldable (toList)
main = do
  print (sum (Sum 3), toList (Dual 'x'), length (First (Just 1)), toList (Last (Nothing :: Maybe Int)))
  r <- traverse (\x -> return (x + 1)) (Alt [1, 2, 3])
  print (getAlt r, toList (Ap (Just 'k')))
  p <- traverse (\x -> print x >> return (x * 2)) (Product 21)
  print (getProduct p)
