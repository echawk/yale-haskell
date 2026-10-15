-- Data.IntMap and IntSet with negative keys (checked against GHC 9.14).
import qualified Data.IntMap as IM
import qualified Data.IntSet as IS
main = do
  let ks = [5, -3, 1000000000000, -4000000000000000000, 3, -1, 4000000000000000000]
      m = IM.fromList (zip ks [1..])
  print (IM.toList m)
  print (map (`IM.lookup` m) ks)
  print (IM.size (IM.insert (-3) 0 m))
  let s = IS.fromList [5, -3, -4000000000000000000, 3, -1]
  print (IS.toList s, IS.member (-3) s, IS.member 4 s)
