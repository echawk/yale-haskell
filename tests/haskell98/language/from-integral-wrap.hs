-- fromIntegral to Int wraps, as GHC's does: through Word and back is the identity.
import Data.Word
main = do
  print (fromIntegral (2 ^ 64 + 5 :: Integer) :: Int)
  print (fromIntegral (fromIntegral (-7 :: Int) :: Word) :: Int)
