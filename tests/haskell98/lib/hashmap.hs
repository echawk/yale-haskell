-- unordered-containers' Data.HashMap.Strict/.Lazy and Data.HashSet (over an
-- IntMap of hash buckets; toList is sorted here, its order being the hash's).
import qualified Data.HashMap.Strict as HM
import qualified Data.HashMap.Lazy as HL
import qualified Data.HashSet as HS
import Data.List (sort)

main :: IO ()
main = do
  let m = HM.fromList [(w, length w) | w <- words "the quick brown fox jumps over the lazy dog"]
      c = HM.fromListWith (+) [(ch, 1 :: Int) | ch <- "mississippi"]
  print (sort (HM.toList m), HM.size m, HM.lookup "fox" m, HM.lookup "cat" m, m HM.!? "dog")
  print (sort (HM.toList c), HM.findWithDefault 0 'z' c, HM.member 's' c)
  print (sort (HM.toList (HM.adjust (* 10) 's' (HM.delete 'm' c))), sort (HM.keys (HM.filter (> 1) c)))
  print (sort (HM.toList (HM.unionWith (+) c (HM.fromList [('s', 100), ('x', 1)]))))
  print (sort (HM.elems (HM.map (+ 1) c)), HM.foldl' (+) 0 c, sum (HL.fromList [(1 :: Int, 2), (3, 4 :: Int)]))
  print (sort (HM.toList (HM.intersectionWith (,) c (HM.fromList [('i', 'I'), ('q', 'Q')]))), HM.null HM.empty)
  let s = HS.fromList "hello world"
  print (sort (HS.toList s), HS.size s, HS.member 'w' s, sort (HS.toList (HS.map succ (HS.fromList [1, 2, 3 :: Int]))))
  print (HM.fromList [(1 :: Int, 'a')] == HM.fromList [(1, 'a')], HM.singleton 'k' True, HS.singleton (5 :: Int))
