module CoreClashA (enumFromTo, Stream(..)) where
import qualified Prelude
import Prelude (Int, (+))
data Stream = Stream [Int]
enumFromTo :: Int -> Int -> Stream
enumFromTo a b = Stream [a + 100, b + 100]
