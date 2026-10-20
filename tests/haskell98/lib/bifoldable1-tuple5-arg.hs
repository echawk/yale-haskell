import Data.Bifoldable1
import Data.Semigroup
main = print (bifoldMap1 (:[]) (:[]) (1, 2, 3, 4, 5), bifold1 (Arg "a" "b"))
