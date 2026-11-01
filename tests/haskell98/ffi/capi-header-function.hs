{-# LANGUAGE CApiFFI #-}
import Foreign.C.Types

foreign import capi "ctype.h isdigit" c_isdigit :: CInt -> CInt
foreign import capi "stdlib.h abs" c_abs :: CInt -> CInt
foreign import capi "math.h fabs" c_fabs :: CDouble -> CDouble
foreign import capi "capihelper.h twice_plus" twicePlus :: CInt -> CInt -> CInt

main :: IO ()
main = do
  print (c_isdigit 55 /= 0, c_isdigit 65 /= 0)
  print (c_abs (-5))
  print (c_fabs (-2.5))
  print (twicePlus 3 4)
