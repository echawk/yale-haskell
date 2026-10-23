module Main where
import Data.Typeable (typeRep, typeRepFingerprint, Proxy(..))
main :: IO ()
main = do
  let a = typeRepFingerprint (typeRep (Proxy :: Proxy [Int]))
      b = typeRepFingerprint (typeRep (Proxy :: Proxy [Int]))
      c = typeRepFingerprint (typeRep (Proxy :: Proxy (Maybe Int)))
  print (a == b, a == c, length (show a))
