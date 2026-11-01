{-# LANGUAGE CApiFFI #-}
import Foreign.C.Types

foreign import capi "limits.h value INT_MAX" intMax :: CInt
foreign import capi unsafe "stdio.h value EOF" cEOF :: CInt
foreign import capi "math.h value M_PI" mPi :: CDouble

main :: IO ()
main = do
  print intMax
  print cEOF
  print (mPi > 3.14 && mPi < 3.15)
