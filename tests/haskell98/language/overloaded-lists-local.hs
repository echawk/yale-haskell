-- A local binding whose constraints sit on a type family application
-- (Item l, OverloadedLists) stays monomorphic in l (alex's UTF8.encode).
{-# LANGUAGE OverloadedLists #-}
import Data.Bits ((.&.), shiftR)
import Data.Char (ord)
import Data.Word (Word8)
import qualified Data.List.NonEmpty as NE

encode :: Char -> NE.NonEmpty Word8
encode = fmap fromIntegral . go . ord
 where
  go oc
   | oc <= 0x7f  = [oc]
   | oc <= 0x7ff = [0xc0 + (oc `shiftR` 6), 0x80 + oc .&. 0x3f]
   | otherwise   = [0xe0 + (oc `shiftR` 12), 0x80 + ((oc `shiftR` 6) .&. 0x3f), 0x80 + oc .&. 0x3f]

main :: IO ()
main = mapM_ (print . NE.toList . encode) "a\233\8364"
