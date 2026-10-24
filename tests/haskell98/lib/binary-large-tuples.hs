-- Binary for 7- to 10-tuples, as binary has (Agda's Serialise encodes
-- a 7-tuple).
module Main where

import Data.Binary
import qualified Data.ByteString.Lazy as L

main :: IO ()
main = do
  let t7 = (1 :: Int, "two", 'c', True, 4.5 :: Double, [6 :: Int], Just (7 :: Word32))
      b7 = encode t7
  print (L.length b7)
  print (decode b7 == t7)
  let t10 = (1 :: Int, 2 :: Int, 3 :: Int, 4 :: Int, 5 :: Int, 6 :: Int, 7 :: Int, 8 :: Int, 9 :: Int, 'x')
  print (decode (encode t10) == t10)
