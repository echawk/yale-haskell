-- Arrays with empty bounds (lo > hi) are legal and have no elements
-- (Report, chapter 16): array, listArray, accumArray, elems, fmap.
import Array

main :: IO ()
main = do
  let a = listArray (0, -1) [] :: Array Int Char
      b = array (1, 0) [] :: Array Int Int
      c = accumArray (+) 0 (5, 4) [] :: Array Int Int
  print (bounds a, elems a, a == a)
  print b
  print (fmap (+ 1) c, elems c, indices c)
  print (listArray ((1, 1), (0, 3)) [] :: Array (Int, Int) Bool)
