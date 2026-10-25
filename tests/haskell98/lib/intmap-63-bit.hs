-- IntMap and IntSet against Map and Set, with keys using all of Yale
-- Haskell's 63-bit Int: negative ones, the extremes, and those at the
-- top bit of IntSet's 64-bit bitmaps (k mod 64 = 63).  containers'
-- iShiftRL shifted a 64-bit Word, so branchMask was wrong
-- (fromDistinctAscList [(97,..),(98,..)] did not find 98).
import qualified Data.IntMap as IM
import qualified Data.IntSet as IS
import qualified Data.Map as M
import qualified Data.Set as S
import Data.List (sort, nub)

keys :: [Int]
keys = nub ([0, 1, 2, 3, 63, 64, 97, 98, 127, 128, -1, -2, -64, -65, 1000, 4095,
             maxBound, maxBound - 1, minBound, minBound + 1, minBound + 63]
            ++ take 200 (iterate (\x -> (x * 6364136223846793005 + 1442695040888963407) `mod` 1000003 - 500000) 7))

main :: IO ()
main = do
  let kvs = zip keys [0 :: Int ..]
      im = IM.fromList kvs
      m = M.fromList kvs
      asc = sort keys
      ima = IM.fromDistinctAscList [(k, k) | k <- asc]
      is = IS.fromList keys
      s = S.fromList keys
      half = take 100 keys
  print (IM.toList im == M.toList m)
  print (all (\k -> IM.lookup k im == M.lookup k m) (keys ++ map (+ 1) keys))
  print (all (\k -> IM.lookup k ima == Just k) asc, IM.keys ima == asc)
  print (IS.toList is == S.toList s, all (`IS.member` is) keys)
  print (IM.keys (IM.restrictKeys im (IS.fromList half)) == sort half)
  print (IM.keys (IM.withoutKeys im (IS.fromList half)) == S.toList (S.fromList keys S.\\ S.fromList half))
  print (IS.toList (IS.union is (IS.fromList [5, 6, 63, 64])) == S.toList (S.union s (S.fromList [5, 6, 63, 64])))
  print (IM.toList (IM.unionWith (+) im ima) == M.toList (M.unionWith (+) m (M.fromList [(k, k) | k <- asc])))
  print (fmap fst (IM.lookupMin im) == Just (minimum keys), fmap fst (IM.lookupMax im) == Just (maximum keys))
  print (IM.split 98 im == (\(a, b) -> (IM.fromList (M.toList a), IM.fromList (M.toList b))) (M.split 98 m))
  let is2 = IS.fromList (map (* 3) keys)
      s2 = S.fromList (map (* 3) keys)
  print (IS.toList (IS.intersection is is2) == S.toList (S.intersection s s2),
         IS.toList (IS.difference is is2) == S.toList (S.difference s s2),
         IS.isSubsetOf (IS.fromList half) is)
  print (IM.foldrWithKey (\k _ acc -> k : acc) [] im == M.keys m,
         IM.keys (IM.filterWithKey (\k _ -> even k) im) == filter even (M.keys m))
