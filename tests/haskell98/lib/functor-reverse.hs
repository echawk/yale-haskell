import Data.Functor.Reverse
import Data.Foldable (toList)
main = do
  let r = Reverse [1, 2, 3 :: Int]
  print (toList r, foldr (:) [] r, sum r, r)
  _ <- traverse print r
  return ()
