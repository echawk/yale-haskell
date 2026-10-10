-- containers (Data.Map, Data.Set, Data.IntMap, Data.IntSet, Data.Sequence, Data.Tree).
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.IntMap as IM
import qualified Data.IntSet as IS
import qualified Data.Sequence as Seq
import Data.Tree

main :: IO ()
main = do
  let m = M.fromList [(3, "c"), (1, "a"), (2, "b")]
  print m
  print (M.lookup 2 m, M.findWithDefault "?" 9 m, M.size m, M.member 1 m)
  print (M.toList (M.insertWith (++) 1 "x" m), M.keys m, M.elems m)
  print (M.foldrWithKey (\k v acc -> show k ++ v ++ acc) "" m)
  print (M.toList (M.unionWith (++) m (M.fromList [(3, "!"), (4, "d")])))
  print (fmap length m, M.filter (/= "b") m, M.adjust (++ "?") 3 m)
  let s = S.fromList "mississippi"
  print (s, S.member 's' s, S.toList (S.map succ s), S.size s)
  print (IM.toList (IM.fromListWith (+) [(5, 1), (3, 2), (5, 10 :: Int)]))
  print (IS.toList (IS.fromList [5, 3, 9, 3]), IS.member 9 (IS.fromList [9]))
  print (Seq.length (Seq.fromList [1, 2, 3 :: Int] Seq.|> 4))
  putStr (drawTree (Node "root" [Node "a" [], Node "b" [Node "c" []]]))
  print (flatten (Node 1 [Node 2 [], Node (3 :: Int) []]))
  print (M.toList (mconcat [M.singleton 'a' 1, M.singleton 'b' (2 :: Int)]))
