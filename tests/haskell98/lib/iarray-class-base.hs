module Main where
import Data.Array.IArray
import Data.Array.Base (IArray(..))
import qualified Data.Array.Base as B

main :: IO ()
main = do
  let a = listArray (0, 4) "hello" :: Array Int Char
  print (bounds a, a ! 1, unsafeAt a 4, numElements a, elems a)
  print (a !? 7, amap succ a ! 0, B.numElements a)
