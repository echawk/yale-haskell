import qualified GHC.Compact as C
main = do
  c <- C.compactWithSharing [1, 2, 3 :: Int]
  print (sum (C.getCompact c))
