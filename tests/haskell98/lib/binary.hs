-- Data.Binary (the built-in binary package): binary's encodings, round
-- trips, Get and Put, the incremental decoder.
import Data.Binary
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString.Lazy as L
import qualified Data.Map as Map

main :: IO ()
main = do
  let v = (42 :: Int, [1, -5, 2 ^ 70 :: Integer], "héllo", Just True, 3.25 :: Double, Map.fromList [(1 :: Int, 'a'), (2, 'λ')])
      b = encode v
  print (L.unpack (encode (300 :: Int)))
  print (L.unpack (encode 'é'))
  print (decode b == v)
  print (runGet ((,) <$> getWord16be <*> getWord32le) (runPut (putWord16be 513 >> putWord32le 7)))
  print (runGet getDoublebe (runPut (putDoublebe 1.5)), L.unpack (runPut (putDoublebe 1.5)))
  print (runGet getFloatle (runPut (putFloatle (-0.1))))
  case runGetIncremental (get :: Get [Int]) `pushChunks` encode [1, 2, 3 :: Int] of
    Partial k -> case k Nothing of
      Done _ n xs -> print (n, xs)
      _ -> putStrLn "fail"
    _ -> putStrLn "not partial"
