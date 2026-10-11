-- Data.Map.Strict: insertWith counting over 400000 pseudo-random keys,
-- then folds, lookups, Data.Set and Data.IntMap.
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import qualified Data.IntMap.Strict as IM
import Data.List (foldl')

lcg :: Int -> Int
lcg x = (x * 1103515245 + 12345) `mod` 2147483648

keys :: Int -> [Int]
keys n = take n (map (`mod` 50000) (iterate lcg 42))

main :: IO ()
main = do
  let ks = keys 400000
      m = foldl' (\acc k -> M.insertWith (+) k (1 :: Int) acc) M.empty ks
  print (M.size m)
  print (M.foldlWithKey' (\a k v -> a + k * v) 0 m)
  print (length (filter (`M.member` m) [0, 7 .. 100000]))
  let s = S.fromList ks
  print (S.size s, S.findMin s, S.findMax s)
  let im = IM.fromListWith (+) [(k `mod` 1000, k) | k <- ks]
  print (IM.size im, IM.foldr (+) 0 im)
