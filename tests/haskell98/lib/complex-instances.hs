import Data.Complex
import Data.Functor.Contravariant
import Data.Proxy
import Data.Foldable (toList)
main = do
  print (fmap (*2) (1 :+ 2 :: Complex Int), toList (3 :+ 4 :: Complex Int), sum (1 :+ 2 :: Complex Int))
  print (traverse Just (1 :+ 2 :: Complex Int), (+) <$> (1 :+ 2) <*> (10 :+ 20 :: Complex Int))
  print (contramap (+ (1 :: Int)) (Proxy :: Proxy Int))
