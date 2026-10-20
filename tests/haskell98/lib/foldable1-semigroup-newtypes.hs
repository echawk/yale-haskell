import qualified Data.Foldable1 as F1
import Data.Semigroup
import Data.Ord (Down(..))
import Data.Monoid (Sum(..), Product(..), Alt(..))
main = print (F1.head (Max 3), F1.toNonEmpty (Min 'a'), F1.last (First True), F1.maximum (Down 9), F1.fold1 (Last [1]))
  >> print (F1.head (Sum 4), F1.toNonEmpty (Alt (Max 'z' )), F1.last (Product 6))
