import Data.Ord
import Data.Foldable (toList)
main = do
  print (fmap (+1) (Down 3), Down (+2) <*> Down 1, Down 5 >>= Down . (*2))
  print (toList (Down 'q'), sum (Down 7), Down [1] <> Down [2])
  r <- traverse (\x -> print x >> return (x * 10)) (Down 4)
  print (getDown r, mempty :: Down String)
