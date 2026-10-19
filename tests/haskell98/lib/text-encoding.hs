-- Data.Text.Encoding: UTF-8 and UTF-16 encoding and decoding, lenient and
-- strict decoding of invalid input.
import qualified Data.Text as T
import qualified Data.Text.Encoding as E
import Data.Text.Encoding.Error (lenientDecode)
import qualified Data.ByteString as B

main :: IO ()
main = do
  let t = T.pack "héllo λ 𝄞"
  print (B.unpack (E.encodeUtf8 t))
  print (E.decodeUtf8 (E.encodeUtf8 t) == t)
  print (E.decodeUtf16LE (E.encodeUtf16LE t) == t)
  print (E.decodeUtf8With lenientDecode (B.pack [104, 255, 105]))
  print (either (const "invalid") T.unpack (E.decodeUtf8' (B.pack [0xC3])))
