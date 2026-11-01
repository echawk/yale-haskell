import Data.Word
import Numeric (showHex)

main :: IO ()
main = do
  putStrLn (showHex (byteSwap16 0x1234) "")
  putStrLn (showHex (byteSwap32 0x12345678) "")
  putStrLn (showHex (byteSwap64 0x0102030405060708) "")
