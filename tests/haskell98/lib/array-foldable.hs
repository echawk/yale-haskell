import Data.Array
import Data.Foldable (toList)
main = do
  let a = listArray (0, 3) [1, 2, 3, 4 :: Int]
  print (sum a, length a, maximum a, toList a, elem 3 a)
  print (traverse (\x -> if x > 0 then Just (x * 2) else Nothing) a)
