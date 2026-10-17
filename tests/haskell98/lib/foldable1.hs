import qualified Data.Foldable1 as F1
import Data.List.NonEmpty (NonEmpty(..))
import Data.Semigroup (Max(..))

main = do
  let ne = 3 :| [1, 4, 1, 5 :: Int]
  print (F1.maximum ne, F1.minimum ne, F1.head ne, F1.last ne)
  print (F1.foldMap1 (: []) ne, getMax (F1.foldMap1 Max ne))
  print (F1.foldr1 (-) ne, F1.foldl1 (-) ne, F1.intercalate1 ", " ("a" :| ["b", "c"]))
  print (F1.toNonEmpty ((), 'x'), F1.maximumBy compare ne)
  r <- F1.foldlM1 (\a b -> print (a, b) >> return (a + b)) ne
  print r
