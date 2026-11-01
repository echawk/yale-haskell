import Control.DeepSeq
import Data.Array.Byte

main :: IO ()
main = print (rnf (mempty :: ByteArray))
