import Prelude (Int, IO, print, ($), sequenceA, Maybe(..), (+))
mapM :: Int
mapM = 1
sequence :: Int
sequence = 2
main :: IO ()
main = print (mapM + sequence, sequenceA [Just 3])
