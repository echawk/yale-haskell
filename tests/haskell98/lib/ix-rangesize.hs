-- rangeSize is an Ix method (Haskell 98 revised), with the Report's default;
-- tuples use it componentwise.
import Ix
data C = R | G | B deriving (Eq, Ord, Ix, Show)
main = do
  print (rangeSize (1::Int,10), rangeSize (5::Int,1), rangeSize ('a','z'))
  print (rangeSize ((0,0),(2,3)) :: Int, rangeSize ((1,'a'),(0,'b')) :: Int)
  print (rangeSize (R,B), index ((0,0),(2,3)) (1,2) :: Int)
  print (range ((0,0,0),(1,1,1)) :: [(Int,Int,Int)])
