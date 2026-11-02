import qualified Data.ByteString as B
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8, Decoding(..), streamDecodeUtf8)

-- a UTF-8 text split inside its multi-byte characters decodes the same
main :: IO ()
main = do
  let bytes = encodeUtf8 (T.pack "h\233llo \8364 \128512!")
      pieces = [B.take 2 bytes, B.take 5 (B.drop 2 bytes), B.drop 7 bytes]
      run dec [] = []
      run dec (p : ps) = let Some t rest next = dec p in (t, B.length rest) : run next ps
  mapM_ print (run streamDecodeUtf8 pieces)
  print (T.concat (map fst (run streamDecodeUtf8 pieces)) == T.pack "h\233llo \8364 \128512!")
