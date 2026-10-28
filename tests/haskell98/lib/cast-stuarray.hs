-- castSTUArray: an unboxed array's elements as another type's bytes (GHC's
-- floatToBytes and doubleToWords).
import Data.Array.ST
import qualified Data.Array.Unsafe as U
import Control.Monad.ST
import Data.Word

castFloatToWord8Array :: STUArray s Int Float -> ST s (STUArray s Int Word8)
castFloatToWord8Array = U.castSTUArray

castDoubleToWord64Array :: STUArray s Int Double -> ST s (STUArray s Int Word64)
castDoubleToWord64Array = U.castSTUArray

floatToBytes :: Float -> [Word8]
floatToBytes f = runST (do
  arr <- newArray_ ((0::Int), 3)
  writeArray arr 0 f
  arr' <- castFloatToWord8Array arr
  mapM (readArray arr') [0 .. 3])

doubleToWord :: Double -> Word64
doubleToWord d = runST (do
  arr <- newArray_ ((0::Int), 0)
  writeArray arr 0 d
  arr' <- castDoubleToWord64Array arr
  readArray arr' 0)

main = do
  print (floatToBytes 1.0)
  print (doubleToWord 1.0)
