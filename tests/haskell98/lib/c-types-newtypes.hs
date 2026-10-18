import Foreign.C.Types
import Foreign.C.String
import Foreign.C.Error
import System.Posix.Internals ()
import System.Posix.Signals ()
import Data.Int
class D a where d :: a -> String
instance D CInt where d _ = "CInt"
instance D Int32 where d _ = "Int32"
main = do
  print (3 :: CInt, fromIntegral (7 :: CInt) + (1 :: Int), (2.5 :: CDouble) * 2, maxBound :: CUChar)
  print (d (1 :: CInt), d (1 :: Int32), castCharToCChar 'a', toBool (1 :: CInt))
  where toBool x = x /= 0
